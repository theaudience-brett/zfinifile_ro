begin
  require 'bones'
rescue LoadError
  abort '### please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'zfinifile'

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name         'zfinifile'
  summary      'INI file reader that supports the inheritance available in Zend Framework'
  authors      'Brett Mack'
  email        'brett.mack@bauermedia.co.uk'
  url          'http://rubygems.org/gems/zfinifile'
  version      ZFIniFile::VERSION

  use_gmail
  depend_on    'bones-git', :development => true
}