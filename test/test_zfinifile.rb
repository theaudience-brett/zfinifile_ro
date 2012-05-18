require 'test/unit'
libpath = File.expand_path '../../lib', __FILE__
require File.join(libpath, 'zfinifile')


class ZFIniFileTest < Test::Unit::TestCase

	def test_no_file_given
		assert_raise ArgumentError do 
			ZFIniFile.load()
		end
	end

	def test_ini_file_not_exists
		assert_raise ZFIniFile::Error do
			ZFIniFile.load('filenotexists.ini')
		end
	end

	def test_instances
		inifile = ZFIniFile.load('test/data/application.ini')
		assert_instance_of ZFIniFile, inifile
		assert_instance_of Hash, inifile.get_section( 'testing' )
		assert_instance_of Hash, inifile.get_section( 'nosuchsection' )
	end

	def test_inheritance
		inifile = ZFIniFile.load('test/data/application.ini')
		testing = inifile.get_section('testing')
		staging = inifile.get_section('staging')
		production = inifile.get_section('production')
		# Make sure dbname has been overwritten in each section
		testkey = "resources.doctrine.dbal.connections.default.parameters.dbname"
		assert_nil [ testing[testkey], production[testkey] ].uniq!

		# Make sure the tester val from staging still exists in testing
		assert_equal "Should still exist in testing", testing["app.url.tester"]

		# Make sure the url.base val from staging was overwritten in testing
		assert_not_equal staging["app.url.base"], testing["app.url.base"]
	end

end