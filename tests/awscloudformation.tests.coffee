Q = require 'q'
should = require 'should'
S = require 'string'

grunt = null
thisPointer = null

getGruntStub = ->
	log:
		writeln: ->
		ok: ->
		error: ->
	verbose:
		writeln: ->
		ok: ->
	fail:
		warn: ->
		fatal: ->
	fatal: ->
	warn: ->
	_options: { }
	option: (key, value) ->
		if value?
			@_options[key] = value
		else
			@_options[key]
	registerTask: ->
	registerMultiTask: ->
	task:
		run: ->
		clearQueue: ->
	template:
		process: ->
	file:
		read: ->

getThisPointer = ->
	data: { }
	async: ->
		return ->

loadGrunt = (grunt) ->

	(require '../awscloudformation.js')(grunt)

beforeEachMethod = ->

	#	Setup the grunt stub.
	grunt = getGruntStub()
	loadGrunt(grunt)

	thisPointer = 
		data: { }
		async: ->
			return ->

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

						called = false
						grunt.warn = ->
							called = true

						thisPointer.data.key = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						called.should.be.true

					it 'should call grunt.warn and return if @data.src is null.', ->

						called = false
						grunt.warn = ->
							called = true

						thisPointer.data.src = null
						thisPointer.data.key = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						called.should.be.true


					it 'should call grunt.warn and return if @data.key is undefined.', ->

						called = false
						grunt.warn = ->
							called = true

						thisPointer.data.src = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						called.should.be.true

					it 'should call grunt.warn and return if @data.key is null.', ->

						called = false
						grunt.warn = ->
							called = true

						thisPointer.data.key = null
						thisPointer.data.src = ""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						called.should.be.true

					it 'should call grunt.file.read with @data.src.', ->

						thisPointer.data.key = ""
						thisPointer.data.src = "Some File Path"

						actualSrc = null
						actualOptions = null
						grunt.file.read = (file, options) ->
							actualSrc = file
							actualOptions = options
						grunt.option = ->
							""

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						actualSrc.should.equal "Some File Path"
						actualOptions.should.eql 
							encoding: "utf8"

					it 'should call grunt.template.process with the output of grunt.file.read(@data.src).', ->

						thisPointer.data.key = ""
						thisPointer.data.src = ""
						thisPointer.data.data = 
							HelloProperty: "Hello"
						actualContent = null
						actualData = null

						grunt.file.read = ->
							"Some Content"
						grunt.template.process = (content, data) ->
							actualContent = content
							actualData = data

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						actualContent.should.equal "Some Content"
						actualData.should.eql
							data:
								HelloProperty: "Hello"

					it 'should place the result of grunt.template.process into grunt.option(@data.key).', ->

						thisPointer.data.key = "Hi"
						thisPointer.data.src = ""
						grunt.template.process = ->
							"Some Value"

						grunt.niteo.aws.cloudFormation.processTemplate.call(thisPointer)

						grunt._options["Hi"].should.equal "Some Value"
						
					it 'should call createJSONStringArray if @data.convertToArray is true.', ->

						thisPointer.data.key = "Hi!"
						thisPointer.data.src = ""
						thisPointer.data.convertToArray = true
						grunt.template.process = ->
							"Some\nValue"

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
						thisPointer.data.name = ""
						thisPointer.data.template = ""
						thisPointer.data.outputKey = ""
						thisPointer.async = ->
							done

						grunt.niteo.aws.cloudFormation.createStack.call(thisPointer)

					it 'should call grunt.warn and return if @data.region is null.'
					it 'should call grunt.warn and return if @data.name is undefined.'
					it 'should call grunt.warn and return if @data.name is null.'
					it 'should call grunt.warn and return if @data.template is undefined.'
					it 'should call grunt.warn and return if @data.template is null.'
					it 'should call grunt.warn and return if @data.outputKey is undefined.'
					it 'should call grunt.warn and return if @data.outputKey is null.'
