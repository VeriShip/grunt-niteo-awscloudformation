	Q = require 'q'
	_ = require 'lodash'
	colors = require 'colors'
	S = require 'string'
	path = require 'path'
	niteoaws = require 'niteoaws'
	moment = require 'moment'

	module.exports = (grunt) ->

		if not grunt.niteo?
			grunt.niteo = { }
		if not grunt.niteo.aws?
			grunt.niteo.aws = { }
		if not grunt.niteo.aws.cloudFormation?
			grunt.niteo.aws.cloudFormation = { }

		grunt.niteo.aws.cloudFormation.createJSONStringArray = (content) ->
			result = [ ]
			for item in S(content).strip('\r').split('\n')
				result.push item
				result.push '\\n'

			JSON.stringify result, null, 4

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

			if not @data.template?
				grunt.fail.fatal "You need to define a template in order to create a stack."
				done()
				return

			if not @data.outputKey?
				grunt.fail.fatal "You need to define a key in order to store the stack metadata once it's created."
				done()
				return

			niteoawsCF = new niteoaws.cloudFormationProvider.factory @data.region 

			content = grunt.option(@data.template)

			if not content?
				grunt.fail.fatal "The template retreived was invalid."

			niteoawsCF.doesStackExist(@data.name)
				.then (result) =>
					promise = Q()
					if not result
						grunt.log.ok "Stack #{@data.name} does not exist."
						promise = niteoawsCF.validateTemplate(content)
						.then =>
							grunt.log.ok "Verified template."
							niteoawsCF.createStack(@data.name, content, @data.parameters)
						.then =>
							grunt.log.ok "Successfully created stack #{@data.name}"
					promise
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

		grunt.registerMultiTask 'processTemplate', grunt.niteo.aws.cloudFormation.processTemplate
		grunt.registerMultiTask 'createStack', grunt.niteo.aws.cloudFormation.createStack
		grunt.registerMultiTask 'deleteStack', grunt.niteo.aws.cloudFormation.deleteStack