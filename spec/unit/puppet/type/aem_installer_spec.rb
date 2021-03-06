#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem_installer'

describe Puppet::Type.type(:aem_installer) do

  before do
    @provider_class = described_class.provide(:simple) { mk_resource_methods }
    @provider_class.stubs(:suitable?).returns true
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  before :each, :platform => :linux do
    expect(Puppet::Util::Platform).to receive(:windows?).and_return(false)
  end

  before :each, :platform => :windows do
    expect(Puppet::Util::Platform).to receive(:windows?).and_return(true)
  end

  describe 'namevar validation' do
    it 'should have :name as its namevar' do
      expect(described_class.key_attributes).to eq([:name])
    end
  end

  describe 'when validating attributes' do
    [:name, :context_root, :port, :snooze, :timeout].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:group, :home, :user, :version].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do

    describe 'ensure' do
      it 'should support present as a value for ensure' do
        expect { described_class.new(:name => 'bar', :ensure => :present, :home => '/opt/aem') }.not_to raise_error
      end

      it 'should support absent as a value for ensure' do
        expect { described_class.new(:name => 'bar', :ensure => :absent, :home => '/opt/aem') }.not_to raise_error
      end

      it 'should not support other values' do
        expect do
          described_class.new(:name => 'bar', :ensure => :bar, :home => '/opt/aem')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'name' do
      it 'should be required' do
        expect { described_class.new({}) }.to raise_error(Puppet::Error, 'Title or name must be provided')
      end

      it 'should accept a name' do
        inst = described_class.new(:name => 'bar', :home => '/opt/aem')
        expect(inst[:name]).to eq('bar')
      end

      it 'should be munged to lowercase' do
        inst = described_class.new(:name => 'BAR', :home => '/opt/aem')
        expect(inst[:name]).to eq('bar')
      end
    end

    describe 'home' do

      it 'should require a value' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent)
        end.to raise_error(Puppet::Error, /Home must be specified/)
      end

      context 'linux', :platform => :linux do

        it 'should require absolute paths' do
          expect do
            described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => 'not/absolute')
          end.to raise_error(Puppet::Error, /fully qualified/)
        end
      end

      context 'windows', :platform => :windows do

        it 'should require absolute paths' do
          expect do
            described_class.new(
              :name => 'bar',
              :ensure => :present,
              :home => 'not/absolute')
          end.to raise_error(Puppet::Error, /fully qualified/)
        end
      end
    end

    describe 'port', :setup => :required do
      it 'should accept a number' do
        inst = described_class.new(:name => 'bar', :ensure => :absent, :home => '/opt/aem', :port => 12_345)
        expect(inst[:port]).to eq(12_345)
      end

      it 'should always be a number' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent, :port => 'NaN')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'snooze' do
      it 'should always be a number' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent, :home => '/opt/aem', :timeout => 'NaN')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'timeout' do
      it 'should always be a number' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent, :home => '/opt/aem', :timeout => 'NaN')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'version' do
      it 'should support valid major/minor format' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent, :home => '/opt/aem', :version => 6.0)
        end.not_to raise_error
      end

      it 'should support valid major/minor/revision format' do
        expect do
          described_class.new(:name => 'bar', :ensure => :absent, :home => '/opt/aem', :version => '6.0.0')
        end.not_to raise_error
      end

      it 'should require minor version' do
        expect do
          described_class.new(:name => 'bar', :home => '/opt/aem', :version => 6)
        end.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should not support beyond bug fix version' do
        expect do
          described_class.new(:name => 'bar', :version => '6.0.0.0')
        end.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should munge to a string' do
        inst = described_class.new(:name => 'bar', :ensure => :absent, :home => '/opt/aem', :version => 6.0)
        inst[:version].class
        expect(inst[:version]).to be_a(String)
      end

    end

  end

end
