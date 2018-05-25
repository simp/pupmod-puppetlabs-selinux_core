# Note: This unit test depends on having a sample SELinux policy file
# in the same directory as this test called selmodule-example
# with version 1.5.0.  The provided selmodule-example is the first
# 256 bytes taken from /usr/share/selinux/targeted/nagios.pp on Fedora 9

require 'spec_helper'
require 'stringio'

provider_class = Puppet::Type.type(:selmodule).provider(:semodule)

describe provider_class do
  before :each do
    @resource = stub('resource', name: 'foo')
    @resource.stubs(:[]).returns 'foo'
    @provider = provider_class.new(@resource)
  end

  describe 'exists? method' do
    it 'finds a module if it is already loaded' do
      @provider.expects(:command).with(:semodule).returns '/usr/sbin/semodule'
      @provider.expects(:execpipe).with('/usr/sbin/semodule --list').yields StringIO.new("bar\t1.2.3\nfoo\t4.4.4\nbang\t1.0.0\n")
      expect(@provider.exists?).to eq(:true)
    end

    it 'returns nil if not loaded' do
      @provider.expects(:command).with(:semodule).returns '/usr/sbin/semodule'
      @provider.expects(:execpipe).with('/usr/sbin/semodule --list').yields StringIO.new("bar\t1.2.3\nbang\t1.0.0\n")
      expect(@provider.exists?).to be_nil
    end

    it 'returns nil if no modules are loaded' do
      @provider.expects(:command).with(:semodule).returns '/usr/sbin/semodule'
      @provider.expects(:execpipe).with('/usr/sbin/semodule --list').yields StringIO.new('')
      expect(@provider.exists?).to be_nil
    end
  end

  describe 'selmodversion_file' do
    it 'returns 1.5.0 for the example policy file' do
      @provider.expects(:selmod_name_to_filename).returns "#{File.dirname(__FILE__)}/selmodule-example"
      expect(@provider.selmodversion_file).to eq('1.5.0')
    end
  end

  describe 'syncversion' do
    it 'returns :true if loaded and file modules are in sync' do
      @provider.expects(:selmodversion_loaded).returns '1.5.0'
      @provider.expects(:selmodversion_file).returns '1.5.0'
      expect(@provider.syncversion).to eq(:true)
    end

    it 'returns :false if loaded and file modules are not in sync' do
      @provider.expects(:selmodversion_loaded).returns '1.4.0'
      @provider.expects(:selmodversion_file).returns '1.5.0'
      expect(@provider.syncversion).to eq(:false)
    end

    it 'returns before checking file version if no loaded policy' do
      @provider.expects(:selmodversion_loaded).returns nil
      expect(@provider.syncversion).to eq(:false)
    end
  end

  describe 'selmodversion_loaded' do
    it 'returns the version of a loaded module' do
      @provider.expects(:command).with(:semodule).returns '/usr/sbin/semodule'
      @provider.expects(:execpipe).with('/usr/sbin/semodule --list').yields StringIO.new("bar\t1.2.3\nfoo\t4.4.4\nbang\t1.0.0\n")
      expect(@provider.selmodversion_loaded).to eq('4.4.4')
    end

    it 'returns raise an exception when running selmodule raises an exception' do
      @provider.expects(:command).with(:semodule).returns '/usr/sbin/semodule'
      @provider.expects(:execpipe).with('/usr/sbin/semodule --list').yields("this is\nan error").raises(Puppet::ExecutionFailure, 'it failed')
      expect { @provider.selmodversion_loaded }.to raise_error(Puppet::ExecutionFailure, %r{Could not list policy modules: ".*" failed with "this is an error"})
    end
  end
end
