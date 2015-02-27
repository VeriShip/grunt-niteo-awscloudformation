awscloudformation.litcoffee
===========================

*Note:* Any code blocks preceeded by a **Implementation** is actual code and not code examples.

**Implementation**

	Q = require 'q'
	_ = require 'lodash'
	colors = require 'colors'
	S = require 'string'
	path = require 'path'
	moment = require 'moment'

	module.exports = (grunt, niteoaws) ->

In order to test the interaction with the [`niteoaws.cloudFormationProvider`](https://github.com/NiteoSoftware/niteoaws), we need to be abstract the object.  Therefore we need to allow that abstraction to be passed into the module.

**Implementation**

		if not niteoaws?
			niteoaws = require 'niteoaws'

We clear up namespaces here.

**Implementation**

		if not grunt.niteo?
			grunt.niteo = { }
		if not grunt.niteo.aws?
			grunt.niteo.aws = { }
		if not grunt.niteo.aws.cloudFormation?
			grunt.niteo.aws.cloudFormation = { }

createJSONStringArray
---------------------

**Implementation**

		grunt.niteo.aws.cloudFormation.createJSONStringArray = (content) ->
			result = [ ]
			for item in S(content).strip('\r').split('\n')
				result.push item
				result.push '\\n'

			JSON.stringify result, null, 4

processTemplate
------------------------------------------------

This method processes a template with path in `this.data.src` and stores the result into `grunt.option(this.data.key)`.

- *src* (Required) The path of the template file.
- *key* (Required) The key used with `grunt.option` to store the result for future use.

**Example**

```javascript
grunt.initConfig({
	processTemplate: {
		src: '/Some/file/path.json'
		key: 'someFilePathJsonKey'
		data: {
			SomeDataNeededWithinTheTemplate: "Hello There!"
		}
	}
});
```

The above example configures grunt to process the template file located at `/Some/file/path.json` with the data object

```json
{
	"data": {
		"SomeDataNeededWithinTheTemplate": "Hello There!"
	}
}
```

Grunt then places the result into `grunt.option('someFilepathJsonKey')` for future use within the grunt run.

**Implementation**

		grunt.niteo.aws.cloudFormation.processTemplate = ->

			if not @data.src?
				grunt.warn "You must define a source template file."
				return

			if not @data.key?
				grunt.warn "You must define a key so that this task can place the template somewhere for future use."
				return

			templateContent = grunt.template.process(grunt.file.read(@data.src, {encoding: "utf8" }), {data:(@data.data ? { })})

			if @data.convertToArray ? false
				templateContent = grunt.niteo.aws.cloudFormation.createJSONStringArray templateContent

			grunt.option(@data.key, templateContent)

			grunt.verbose.writeln "#{@data.key}:"['gray']
			grunt.verbose.writeln grunt.option(@data.key)['gray']
			grunt.log.ok "Created template from #{@data.src} and placed it in grunt.option(\"#{@data.key}\")"

createStack
------------------------------------------

This task handles creating a stack within [AWS Cloud Formation](http://aws.amazon.com/cloudformation/).

- *region* (Required) The [region](http://aws.amazon.com/about-aws/global-infrastructure/) to create the stack in.
- *name* (Required) The name of the stack
- *templateKey* (Required) A string that is used with `grunt.option` in order to find the text used for the template. The `processTemplate` method shows us how to get the contents of a template into `grunt.option`.
- *outputKey* (Required) A string representing where in `grunt.option` to place the JSON metadata of the created stack.  You can use this metadata within other tasks.

**Example**
```javascript
grunt.initConfig({
	processTemplate: {
		src: '/Some/file/path.json',
		key: 'someFilePathJsonKey',
		data: {
			SomeDataNeededWithinTheTemplate: "Hello There!"
		}
	},
	createStack: {
		region: "us-east-1",
		name: "MyStack",
		templateKey: "someFilePathJsonKey",
		outputKey: "MyStackMetadata"
	}
});

grunt.registerTask('default', [ 'processTemplate', 'createStack' ])
```

This example uses the output from the `processTemplate` to feed the `createStack` task which creates a new stack within the `us-east-1` region called *MyStack*.  It then stores the metadata of that stack within `grunt.option('MyStackMetadata')`

**Implementation**

		grunt.niteo.aws.cloudFormation.createStack = ->

			done = @async()

			if not @data.region?
				grunt.fail.fatal "You need to define a region in order to create a stack."
				done()
				return

			if not @data.name?
				grunt.fail.fatal "You need to define a stack name in order to create a stack."
				done()
				return

			if not @data.templateKey?
				grunt.fail.fatal "You need to define a template key in order to create a stack."
				done()
				return

			if not @data.outputKey?
				grunt.fail.fatal "You need to define a key in order to store the stack metadata once it's created."
				done()
				return

			niteoawsCF = niteoaws.cloudFormationProvider.factory @data.region

			content = grunt.option(@data.templateKey)

			if not content?
				grunt.fail.fatal "The template retreived was invalid."
				done()
				return

			niteoawsCF.doesStackExist(@data.name)
				.then (result) =>
					if not result
						grunt.log.ok "Stack #{@data.name} does not exist."
						niteoawsCF.validateTemplate(content)
							.then =>
								grunt.log.ok "Template Validated."
								niteoawsCF.createStack(@data.name, content, @data.parameters, @data.capabilities)
							.then =>
								grunt.log.ok "Successfully created stack #{@data.name}"
				.then =>
					niteoawsCF.getStackId(@data.name)
				.then (result)=>
					grunt.log.ok "Successfully retreived the stack id #{result}"
					niteoawsCF.getResource(result)
				.done (result) =>
						grunt.verbose.writeln JSON.stringify(result, null, 4)['gray']
						grunt.option(@data.outputKey, result)
						grunt.log.ok "Successfully retreived the stack metadata and placed it into grunt.option(#{@data.outputKey})"
						done()
					, (err) ->
						grunt.fail.fatal err
						done()
					, (progress) ->
						grunt.log.writeln "#{moment().format()}: #{progress}"['gray']

updateStack
------------------------------------------

This task handles updating a stack within [AWS Cloud Formation](http://aws.amazon.com/cloudformation/).

- *region* (Required) The [region](http://aws.amazon.com/about-aws/global-infrastructure/) to update the stack in.
- *name* (Required) The name of the stack
- *templateKey* (Required) A string that is used with `grunt.option` in order to find the text used for the template. The `processTemplate` method shows us how to get the contents of a template into `grunt.option`.
- *outputKey* (Required) A string representing where in `grunt.option` to place the JSON metadata of the updated stack.  You can use this metadata within other tasks.

**Example**
```javascript
grunt.initConfig({
	processTemplate: {
		src: '/Some/file/path.json',
		key: 'someFilePathJsonKey',
		data: {
			SomeDataNeededWithinTheTemplate: "Hello There!"
		}
	},
	updateStack: {
		region: "us-east-1",
		name: "MyStack",
		templateKey: "someFilePathJsonKey",
		outputKey: "MyStackMetadata"
	}
});

grunt.registerTask('default', [ 'processTemplate', 'updateStack' ])
```

This example uses the output from the `processTemplate` to feed the `updateStack` task which updates an existing stack within the `us-east-1` region called *MyStack*.  It then stores the metadata of that stack within `grunt.option('MyStackMetadata')`

**Implementation**

		grunt.niteo.aws.cloudFormation.updateStack = ->

			done = @async()

			if not @data.region?
				grunt.fail.fatal "You need to define a region in order to create a stack."
				done()
				return

			if not @data.name?
				grunt.fail.fatal "You need to define a stack name in order to create a stack."
				done()
				return

			if not @data.templateKey?
				grunt.fail.fatal "You need to define a template key in order to create a stack."
				done()
				return

			if not @data.outputKey?
				grunt.fail.fatal "You need to define a key in order to store the stack metadata once it's updated."
				done()
				return

			niteoawsCF = niteoaws.cloudFormationProvider.factory @data.region

			content = grunt.option(@data.templateKey)

			if not content?
				grunt.fail.fatal "The template retreived was invalid."
				done()
				return

			niteoawsCF.doesStackExist(@data.name)
				.then (result) =>
					if not result
						grunt.fail.fatal "Stack #{@data.name} does not exist."
						return
					else
						grunt.log.ok "Stack #{@data.name} exists and can be updated."
						niteoawsCF.validateTemplate(content)
							.then =>
								grunt.log.ok "Template Validated."
								niteoawsCF.updateStack(@data.name, content, @data.parameters, @data.capabilities)
							.then =>
								grunt.log.ok "Successfully updated stack #{@data.name}"
				.then =>
					niteoawsCF.getStackId(@data.name)
				.then (result)=>
					grunt.log.ok "Successfully retreived the stack id #{result}"
					niteoawsCF.getResource(result)
				.done (result) =>
						grunt.verbose.writeln JSON.stringify(result, null, 4)['gray']
						grunt.option(@data.outputKey, result)
						grunt.log.ok "Successfully retreived the stack metadata and placed it into grunt.option(#{@data.outputKey})"
						done()
					, (err) ->
						if err.message == "No updates are to be performed." then grunt.log.writeln err else grunt.fail.fatal err
						done()
					, (progress) ->
						grunt.log.writeln "#{moment().format()}: #{progress}"['gray']

deleteStack
------------------------------------------

This task handles deleting a stack from within [AWS Cloud Formation](http://aws.amazon.com/cloudformation/).

- *region* (Required) The [region](http://aws.amazon.com/about-aws/global-infrastructure/) to create the stack in.
- *name* (Required) The name of the stack

**Example**
```javascript
grunt.initConfig({
	processTemplate: {
		src: '/Some/file/path.json',
		key: 'someFilePathJsonKey',
		data: {
			SomeDataNeededWithinTheTemplate: "Hello There!"
		}
	},
	createStack: {
		region: "us-east-1",
		name: "MyStack",
		templateKey: "someFilePathJsonKey",
		outputKey: "MyStackMetadata"
	},
	deleteStack: {
		region: "us-east-1",
		name: "MyStack"
	}
});

grunt.registerTask('default', [ 'processTemplate', 'createStack', 'deleteStack' ]);
```

This example uses the output from the `processTemplate` to feed the `createStack` task which creates a new stack within the `us-east-1` region called *MyStack*.  It then stores the metadata of that stack within `grunt.option('MyStackMetadata')`.  Finally, the stack is deleted.

**Implementation**

		grunt.niteo.aws.cloudFormation.deleteStack = ->

			done = @async()

			if not @data.region?
				grunt.fail.fatal "You need to define a region in order to create a stack."

			if not @data.name?
				grunt.fail.fatal "You need to define a stack name in order to create a stack."

			niteoawsCF = new niteoaws.cloudFormationProvider.factory @data.region 

			niteoawsCF.deleteStack(@data.name)
				.done (result) ->
						grunt.verbose.writeln JSON.stringify(result, null, 4)['gray']
						grunt.log.ok "Success"
						done()
					, (err) ->
						grunt.fail.fatal err
						done()
					, (progress) ->
						grunt.log.writeln "#{moment().format()}: #{progress}"['gray']

Grunt Task Registrations
------------------------

**Implementations**

		grunt.registerMultiTask 'processTemplate', grunt.niteo.aws.cloudFormation.processTemplate
		grunt.registerMultiTask 'createStack', grunt.niteo.aws.cloudFormation.createStack
		grunt.registerMultiTask 'updateStack', grunt.niteo.aws.cloudFormation.updateStack
		grunt.registerMultiTask 'deleteStack', grunt.niteo.aws.cloudFormation.deleteStack