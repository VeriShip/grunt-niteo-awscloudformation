path = require 'path'
S = require 'string'
fs = require 'fs'
niteoaws = require 'niteoaws'

module.exports = (grunt) =>

	grunt.initConfig
		createDirectories:
			dir: ['tasks']
		cleanUpDirectories:
			dir: ['tasks']
		coffee:
			compile:
				expand: true,
				flatten: false,
				dest: 'tasks',
				src: ['**/*.coffee', '!**/gruntfile*','**/*.litcoffee'],
				ext: '.js',
				cwd: 'lib'
			compileTests:
				expand: true,
				flatten: false,
				dest: 'tasks/tests',
				src: ['**/*.coffee', '!**/gruntfile*'],
				ext: '.js',
				cwd: 'tests'
		mochaTest:
			test:
				options:
					reporter: 'spec'
				src: ['tasks/tests/**/*.js']


	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-mocha-test');

	grunt.registerTask('default', [ 'createDirectories', 'coffee:compile', 'coffee:compileTests', 'mochaTest:test' ]);
	grunt.registerTask('clean', [ 'cleanUpDirectories' ]);
	grunt.registerTask('rebuild', [ 'clean', 'build' ]);

	grunt.registerMultiTask 'createDirectories', ->
		for dir in this.data
			if not grunt.file.exists dir
				grunt.file.mkdir dir

	grunt.registerMultiTask 'cleanUpDirectories', ->
		for dir in this.data
			if grunt.file.exists dir
				grunt.file.recurse dir, (abspath) ->
					grunt.file.delete abspath
				grunt.file.delete dir, { force: true }