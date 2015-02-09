#!/usr/bin/ruby
require 'json'
require 'rexml/document'
require 'pp'
require 'colorize'

include REXML

# Parse conf file
conf = JSON.parse(File.read('./mtree.conf.json'))

projects = Hash.new # hash of projects

conf.each do |folder|
	pom = Document.new(File.new(folder + '/pom.xml'), {
		:ignore_whitespace_nodes => :all
	})

	# Get artifactId
	id = pom.elements['project'].elements['artifactId'].text

	# Get artifact's version
	unless pom.elements['project'].elements['version'].nil?
		version = pom.elements['project'].elements['version'].text
	else
		version = pom.elements['project'].elements['parent'].elements['version'].text
	end

	projects[id] = {
		'version' => version,
		'dependencies' => Hash.new
	}
	
	# puts id + ' ' + version
	# puts '>>> Dependencies:'

	# Check artifact's dependencies
	unless pom.elements['project'].elements['dependencies'].nil?
		pom.elements['project'].elements['dependencies'].each do |dependency|
			unless dependency.instance_of? REXML::Comment
				dId = dependency.elements['artifactId'].text
				# puts dId
				unless dependency.elements['version'].nil?
					dVersion = dependency.elements['version'].text
					if dVersion == '${project.version}'
						dVersion = version
					end
					projects[id]['dependencies'][dId] = dVersion
					# puts dVersion
				end
			end
		end
	end
end

# pp projects

# Now check for the versions
projects.each do |id, desc|
	diffs = [] # differences
	desc['dependencies'].each do |dId, dVersion|
		# If project with this id in the hash
		unless projects[dId].nil?
			if dVersion != projects[dId]['version']
				diffs.push({
					'id' => dId,
					'askedV' => dVersion,
					'currentV' => projects[dId]['version']
				})
			end
		end
	end
	unless diffs.empty?
		puts id.yellow
		diffs.each do |diff|
			puts 'ask ' + diff['id'].magenta + ':' + diff['askedV'].blue + ' current: ' + diff['currentV'].green
		end
		puts
	end
end