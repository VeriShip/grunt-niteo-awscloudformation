Q = require 'q'
should = require 'should'
S = require 'string'
niteo = require 'niteoaws'
sinon = require 'sinon'

grunt = null
thisPointer = null
cloudFormationProviderFactoryStub = null
cloudFormationProviderStub = null

getGruntStub = ->
	log:
		writeln: sinon.stub()
		ok: sinon.stub()  #console.log
		error: sinon.stub()
	verbose:
		writeln: sinon.stub()
		ok: sinon.stub()
	fail:
		warn: sinon.stub()
		fatal: sinon.stub()
	fatal: sinon.stub()
	warn: sinon.stub()
	_options: { }
	option: (key, value) ->
		if value?
			@_options[key] = value
		else
			@_options[key]
	registerTask: sinon.stub()
	registerMultiTask: sinon.stub()
	task:
		run: sinon.stub()
		clearQueue: sinon.stub()
	template:
		process: sinon.stub()
	file:
		read: sinon.stub()

getThisPointer = ->
	data: { }
	async: ->
		return ->

loadGrunt = (grunt) ->

	(require '../awscloudformation.js')(grunt, niteo)

beforeEachMethod = ->

	#	Setup the grunt stub.
	grunt = getGruntStub()
	loadGrunt(grunt)

	thisPointer =
		data: { }
		async: ->
			return ->

	cloudFormationProviderStub =
		getResource: sinon.stub().returns Q(true)
		getResources: sinon.stub().returns Q(true)
		validateTemplate: sinon.stub().returns Q(true)
		doesStackExist: sinon.stub().returns Q(true)
		getStackId: sinon.stub().returns Q(true)
		pollStackStatus: sinon.stub().returns Q(true)
		createStack: sinon.stub().returns Q(true)
		deleteStack: sinon.stub().returns Q(true)
		updateStack: sinon.stub().returns Q(true)

	cloudFormationProviderFactoryStub?.restore()
	cloudFormationProviderFactoryStub = sinon.stub(niteo.cloudFormationProvider, "factory")
	cloudFormationProviderFactoryStub.returns cloudFormationProviderStub

describe 'grunt', ->

	beforeEach beforeEachMethod

	describe 'niteo', ->

		it 'should define the grunt.niteo namespace when it does not already exist.', ->

			grunt.niteo.should.be.ok

		it 'should not overwrite the grunt.niteo namespace if it is already defined.', ->

			grunt = getGruntStub()
			grunt.niteo =
				SomeOtherObject: { }

			loadGrunt(grunt)

			grunt.niteo.should.be.ok
			grunt.niteo.SomeOtherObject.should.be.ok

		describe 'aws', ->

			it 'should define the grunt.niteo.aws namespace when it does not already exist.', ->

				grunt.niteo.aws.should.be.ok

			it 'should not overwrite the grunt.niteo.aws namespace if it is already defined.', ->

				grunt = getGruntStub()
				grunt.niteo =
					aws:
						SomeOtherObject: { }

				loadGrunt(grunt)

				grunt.niteo.aws.should.be.ok
				grunt.niteo.aws.SomeOtherObject.should.be.ok

			describe 'cloudFormation', ->

				it 'should define the grunt.niteo.aws.cloudFormation namespace when it does not already exist.', ->

					grunt.niteo.aws.cloudFormation.should.be.ok

				it 'should not overwrite the grunt.niteo.aws.cloudFormation namespace if it is already defined.', ->

					grunt = getGruntStub()
					grunt.niteo =
						aws:
							cloudFormation:
								SomeOtherObject: { }

					loadGrunt(grunt)

					grunt.niteo.aws.cloudFormation.should.be.ok
					grunt.niteo.aws.cloudFormation.SomeOtherObject.should.be.ok

				describe 'createJSONStringArray', ->

					it 'should strip \\r from content.', ->

						content = 'line1\r\nline2'
						result = grunt.niteo.aws.cloudFormation.createJSONStringArray.call(thisPointer, content)

						for line in result
							line.should.not.containEql '\r'

					it 'should create an array from content where each line is an item in the array.', ->

						content = 'line1\r\nline2\nline3'
						result = grunt.niteo.aws.cloudFormation.createJSONStringArray.call(thisPointer, content)

						lines = S(result).lines()
						S(lines[0]).trim().s.should.equal '['
						S(lines[1]).trim().s.should.equal '"line1",'
						S(lines[2]).trim().s.should.equal '"\\\\n",'
						S(lines[3]).trim().s.should.equal '"line2",'
						S(lines[4]).trim().s.should.equal '"\\\\n",'
						S(lines[5]).trim().s.should.equal '"line3",'
						S(lines[6]).trim().s.should.equal '"\\\\n"'
						S(lines[7]).trim().s.should.equal ']'

				describe 'processTemplate', ->

					it 'should call grunt.warn and return if @data.src is undefined.', ->

						thisPointer.data.key = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt.warn.calledOnce.should.be.true

					it 'should call grunt.warn and return if @data.src is null.', ->

						thisPointer.data.src = null
						thisPointer.data.key = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt.warn.calledOnce.should.be.true


					it 'should call grunt.warn and return if @data.key is undefined.', ->

						thisPointer.data.src = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt.warn.calledOnce.should.be.true

					it 'should call grunt.warn and return if @data.key is null.', ->

						thisPointer.data.key = null
						thisPointer.data.src = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt.warn.calledOnce.should.be.true

					it 'should call grunt.file.read with @data.src.', ->

						thisPointer.data.key = ""
						thisPointer.data.src = "Some File Path"

						grunt.option = ->
							""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt.file.read.calledOnce.should.be.true
						grunt.file.read.alwaysCalledWithExactly("Some File Path", { encoding: "utf8" })

					it 'should call grunt.template.process with the output of grunt.file.read(@data.src).', ->

						thisPointer.data.key = ""
						thisPointer.data.src = ""
						thisPointer.data.data =
							HelloProperty: "Hello"

						grunt.file.read.returns "Some Content"
						grunt.template.process.returns "Some Template Content"

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt.template.process.calledOnce.should.be.true
						grunt.template.process.alwaysCalledWithExactly("Some Content",
							data:
								HelloProperty: "Hello"
						)

					it 'should place the result of grunt.template.process into grunt.option(@data.key).', ->

						thisPointer.data.key = "Hi"
						thisPointer.data.src = ""
						grunt.template.process.returns "Some Value"

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt._options["Hi"].should.equal "Some Value"

					it 'should call createJSONStringArray if @data.convertToArray is true.', ->

						thisPointer.data.key = "Hi!"
						thisPointer.data.src = ""
						thisPointer.data.convertToArray = true
						grunt.template.process.returns "Some\nValue"

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						lines = S(grunt._options["Hi!"]).lines()
						S(lines[0]).trim().s.should.equal '['
						S(lines[1]).trim().s.should.equal '"Some",'
						S(lines[2]).trim().s.should.equal '"\\\\n",'
						S(lines[3]).trim().s.should.equal '"Value",'
						S(lines[4]).trim().s.should.equal '"\\\\n"'
						S(lines[5]).trim().s.should.equal ']'

				describe 'createStack', ->

					it 'should call grunt.warn and return if @data.region is undefined.', (done) ->

						#thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.region is null.', (done) ->

						called = false
						thisPointer.data.region = null
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.name is undefined.', (done) ->

						called = false
						thisPointer.data.region = ""
						#thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.name is null.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = null
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.templateKey is undefined.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						#thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.templateKey is null.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = null
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.outputKey is undefined.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						#thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.outputKey is null.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = null
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should create new cloud formation provider with given region.', (done) ->

						thisPointer =
							data:
								region: 'Some Region'
								name: ""
								templateKey: ""
								outputKey: ""
							async: ->
								return ->
									cloudFormationProviderFactoryStub.calledOnce.should.be.true
									cloudFormationProviderFactoryStub.alwaysCalledWithExactly 'Some Region'
									done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.fail.fatal if the value at grunt.option("@data.templateKey") is undefined.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: ""
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									done()

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.fail.fatal if the value at grunt.option("@data.templateKey") is null.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: ""
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									done()

						grunt.option thisPointer.templateKey, null
						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call doesStackExist with the name of the stack.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									cloudFormationProviderStub.doesStackExist.calledOnce.should.be.true
									cloudFormationProviderStub.doesStackExist.alwaysCalledWithExactly(thisPointer.data.name).should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.fail.fatal if doesStackExist errors', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")
						cloudFormationProviderStub.doesStackExist.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call validateTemplate with template content if stack does not exist.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
							async: ->
								return ->
									cloudFormationProviderStub.validateTemplate.calledOnce.should.be.true
									cloudFormationProviderStub.validateTemplate.alwaysCalledWithExactly("Some Content").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(false)

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.fail.fatal if validateTemplate errors and if stack does not exist.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(false)
						cloudFormationProviderStub.validateTemplate.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call createStack with @data.name and template content if stack does not exist.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
								capabilities: "Some Capabilities"
							async: ->
								return ->
									cloudFormationProviderStub.createStack.calledOnce.should.be.true
									cloudFormationProviderStub.createStack.alwaysCalledWithExactly("Some Name", "Some Content", "Some Parameters", "Some Capabilities").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(false)

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.fail.fatal if createStack fails and template content if stack does not exist.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(false)
						cloudFormationProviderStub.createStack.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call getStackId with @data.name.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									cloudFormationProviderStub.getStackId.calledOnce.should.be.true
									cloudFormationProviderStub.getStackId.alwaysCalledWithExactly("Some Name").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(false)

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.fail.fatal if getStackId fails.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getStackId.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call getResource with result of getStackId.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									cloudFormationProviderStub.getResource.calledOnce.should.be.true
									cloudFormationProviderStub.getResource.alwaysCalledWithExactly("Stack Id").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getStackId.returns Q("Stack Id")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.fail.fatal if getResource fails.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getResource.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should place the result of getResource into grunt.option(@data.outputKey)', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"

						thisPointer.async = ->
							return ->
								grunt.option(thisPointer.data.outputKey).should.equal "ResourceData"
								done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getResource.returns Q("ResourceData")

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

				describe 'updateStack', ->

					it 'should call grunt.warn and return if @data.region is undefined.', (done) ->

						#thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.region is null.', (done) ->

						called = false
						thisPointer.data.region = null
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.name is undefined.', (done) ->

						called = false
						thisPointer.data.region = ""
						#thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.name is null.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = null
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.templateKey is undefined.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						#thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.templateKey is null.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = null
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.outputKey is undefined.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						#thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.outputKey is null.', (done) ->

						called = false
						thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = null
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should create new cloud formation provider with given region.', (done) ->

						thisPointer =
							data:
								region: 'Some Region'
								name: ""
								templateKey: ""
								outputKey: ""
							async: ->
								return ->
									cloudFormationProviderFactoryStub.calledOnce.should.be.true
									cloudFormationProviderFactoryStub.alwaysCalledWithExactly 'Some Region'
									done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if the value at grunt.option("@data.templateKey") is undefined.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: ""
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									done()

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if the value at grunt.option("@data.templateKey") is null.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: ""
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									done()

						grunt.option thisPointer.templateKey, null
						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call doesStackExist with the name of the stack.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									cloudFormationProviderStub.doesStackExist.calledOnce.should.be.true
									cloudFormationProviderStub.doesStackExist.alwaysCalledWithExactly(thisPointer.data.name).should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if doesStackExist errors', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: ""
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")
						cloudFormationProviderStub.doesStackExist.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if stack does not exist.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									grunt.fail.fatal.alwaysCalledWithExactly("The stack #{thisPointer.data.name} does not exist.").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(false)

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if validateTemplate errors and if stack exists.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(true)
						cloudFormationProviderStub.validateTemplate.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call updateStack with @data.name and template content if stack exists.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
								capabilities: "Some Capabilities"
							async: ->
								return ->
									cloudFormationProviderStub.updateStack.calledOnce.should.be.true
									cloudFormationProviderStub.updateStack.alwaysCalledWithExactly("Some Name", "Some Content", "Some Parameters", "Some Capabilities").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(true)

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if updateStack fails and template content if stack exists.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(true)
						cloudFormationProviderStub.updateStack.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call getStackId with @data.name.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									cloudFormationProviderStub.getStackId.calledOnce.should.be.true
									cloudFormationProviderStub.getStackId.alwaysCalledWithExactly("Some Name").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.doesStackExist.returns Q(false)

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if getStackId fails.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getStackId.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call getResource with result of getStackId.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									cloudFormationProviderStub.getResource.calledOnce.should.be.true
									cloudFormationProviderStub.getResource.alwaysCalledWithExactly("Stack Id").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getStackId.returns Q("Stack Id")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should call grunt.fail.fatal if getResource fails.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce
									grunt.fail.fatal.alwaysCalledWithExactly("Random Failure").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getResource.returns Q.reject("Random Failure")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

					it 'should place the result of getResource into grunt.option(@data.outputKey)', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"

						thisPointer.async = ->
							return ->
								grunt.option(thisPointer.data.outputKey).should.equal "ResourceData"
								done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.getResource.returns Q("ResourceData")

						grunt.niteo.aws.cloudFormation.updateStack.call(thisPointer)

				describe 'deleteStack', ->

					it 'should call grunt.fail.fatal and return if @data.region is undefined.', (done) ->

						#thisPointer.data.region = ""
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.deleteStack.call(thisPointer)

					it 'should call grunt.fail.fatal and return if @data.region is null.', (done) ->

						thisPointer.data.region = null
						thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.deleteStack.call(thisPointer)

					it 'should call grunt.fail.fatal and return if @data.name is undefined.', (done) ->

						thisPointer.data.region = ""
						#thisPointer.data.name = ""
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.deleteStack.call(thisPointer)

					it 'should call grunt.fail.fatal and return if @data.name is null.', (done) ->

						thisPointer.data.region = ""
						thisPointer.data.name = null
						thisPointer.data.templateKey = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							return ->
								grunt.fail.fatal.calledOnce.should.be.true
								done()

						grunt.niteo.aws.cloudFormation.deleteStack.call(thisPointer)

					it 'should create new cloud formation provider with given region.', (done) ->

						thisPointer =
							data:
								region: 'Some Region'
								name: ""
								templateKey: ""
								outputKey: ""
							async: ->
								return ->
									cloudFormationProviderFactoryStub.calledOnce.should.be.true
									cloudFormationProviderFactoryStub.alwaysCalledWithExactly('Some Region').should.be.true
									done()

						grunt.niteo.aws.cloudFormation.deleteStack.call(thisPointer)

					it 'should call deleteStack with @data.name.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									cloudFormationProviderStub.deleteStack.calledOnce.should.be.true
									cloudFormationProviderStub.deleteStack.alwaysCalledWithExactly('Some Name').should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						grunt.niteo.aws.cloudFormation.deleteStack.call(thisPointer)

					it 'should call grunt.fail.fatal if deleteStack fails.', (done) ->

						thisPointer =
							data:
								region: "Some Region"
								name: "Some Name"
								templateKey: "Some Key"
								outputKey: "Some OutputKey"
								parameters: "Some Parameters"
							async: ->
								return ->
									grunt.fail.fatal.calledOnce.should.be.true
									grunt.fail.fatal.alwaysCalledWithExactly("Random Error Dude!").should.be.true
									done()

						grunt.option(thisPointer.data.templateKey, "Some Content")

						cloudFormationProviderStub.deleteStack.returns Q.reject("Random Error Dude!")

						grunt.niteo.aws.cloudFormation.deleteStack.call(thisPointer)
