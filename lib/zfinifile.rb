#
# This class is used to load and parse the ini file. Much has been borrowed from the existing gem
# 'inifile' (https://github.com/TwP/inifile) which I would suggest using if you don't need section 
# inheritance.
#

#encoding: UTF-8

class ZFIniFile

	# :stopdoc:
	class Error < StandardError; end
	VERSION = '1.0.0'
	# :startdoc:

	#
	# call-seq:
	# 	ZFIniFile.load( filename )
	# 	ZFIniFile.load( filename, options )
	#
	# Open the given _filename_ and load the contents of the INI file.
	# The following _options_ can be passed to this method:
	#
	# 	:comment => ';'		The line comment character
	# 	:parameter => '='	The parameter / value seperator
	# 	:encoding => nil	The encoding to use when reading a file (RUBY 1.9)
	# 	:inheritance => ':'	The character within a section that denotes inheritance
	#
	def self.load( filename, opts = {} )
		new(filename, opts)
	end

	#
	# call-seq:
	# 	ZFIniFile.new( filename )
	# 	ZFIniFile.new( filename, options )
	#
	# Open the given _filename_ and load the contents of the INI file.
	# The following _options_ can be passed to this method:
	#
	# 	:comment => ';'		The line comment character
	# 	:parameter => '='	The parameter / value seperator
	# 	:encoding => nil	The encoding to use when reading a file (RUBY 1.9)
	# 	:inheritance => ':'	The character within a section that denotes inheritance
	#
	def initialize( filename, opts = {} )
		@fn = filename
		@comment = opts.fetch(:comment, ';')
		@param = opts.fetch(:parameter, '=')
		@encoding = opts.fetch(:encoding, nil)
		@inheritance = opts.fetch(:inheritance, ':')
		@ini = Hash.new { |h,k| h[k] = Hash.new }
		@inihash = Hash.new { |h,k| h[k] = Hash.new }
		@inheritsfrom = Hash.new { |h,k| h[k] = [] }

		@rgxp_comment = %r/\A\s*\z|\A\s*[#{@comment}]/
		@rgxp_section = %r/\A\s*\[([^\]]+)\]/
		@rgxp_param   = %r/[^\\]#{@param}/

		parsefile
	end

	#
	# call-seq:
	# 	get_section( section )
	#
	# Return the _section_ of the inifile as a Hash.
	#
	def get_section( section )
		return unless @ini[section]
		@ini[section]
	end

	def get_hash
		@inihash
	end

	private

	def parsefile
		return unless File.file?(@fn)

		@_current_section = nil
		@_section_name = nil

		fd = (RUBY_VERSION >= '1.9' && @encoding) ?
			File.open(@fn, 'r', :encoding => @encoding) :
			File.open(@fn, 'r')

		while line = fd.gets
			line = line.chomp

			if line =~ @rgxp_comment
				next
			end

			if line =~ @rgxp_section
				section = $1.split("#{@inheritance}")
				inheritsFrom = nil
				if section.length == 2
					inheritsFrom = section[1].strip
				end
				@_section_name = section[0].strip
				@_current_section = @inihash[section[0].strip]
				@_current_section[:inherits] = inheritsFrom
				@_current_section[:params] = {}
				next
			end

			get_properties line
		end

	ensure
		fd.close if defined? fd and fd
		@_current_section = nil
	end

	# Parse tge ini file contents.
	#
	def parse
		raise Error, "Unable to open file: #{@fn}" unless File.file?(@fn)

		@_current_section = nil
		@_current_value = nil
		@_current_param = nil

		fd = (RUBY_VERSION >= '1.9' && @encoding) ?
			File.open(@fn, 'r', :encoding => @encoding) :
			File.open(@fn, 'r')

		while line = fd.gets
			line = line.chomp

			if line =~ @rgxp_comment
				next
			end

			if line =~ @rgxp_section
				section = $1.split("#{@inheritance}")
				@_current_section = @ini[section[0].strip]
				if section.length == 2
					@inheritsfrom[section[1].strip].unshift(section[0].strip)
				end
				next
			end

			#So it't not a comment and it's not a section. Process the line as param = value
			parse_property line
		end

		@inheritsfrom.each { |key, val|
			next unless @ini[key]
			@_inherit_base = @ini[key]
			val.each do |d|
				next unless @ini[d]
				@ini[d] = @_inherit_base.merge(@ini[d])
			end
		}
	ensure
		fd.close if defined? fd and fd
		@_current_section = nil
		@_current_param = nil
		@_current_value = nil
	end

	# Parse the ini file line as param = value
	#
	def parse_property( line )
		return unless @_current_section
		param, value = line.split("#{@param}")
		@_current_section[param.strip] = value.strip.gsub(/["']/, '')
	end

	def get_properties( line )
		param, value = line.split("#{@param}")
		
		curGroup = @_current_section[:params]
		param = param.split('.')
		param.each_with_index do |p, index|
			p = p.strip
			if index == param.size - 1
				if p =~ %r/\[\]$/
					p = p[0..-3] 
					curGroup[p] = [] unless curGroup.has_key?(p)
					curGroup[p].unshift(value.strip)
				else
					curGroup[p] = value.strip
				end
			else
				curGroup[p] = {} unless curGroup.has_key?(p)
				curGroup = curGroup[p]
			end
		end

	end
end