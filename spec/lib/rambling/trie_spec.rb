# frozen_string_literal: true

require 'spec_helper'

describe Rambling::Trie do
  describe '.create' do
    let(:root) { Rambling::Trie::Nodes::Raw.new }
    let(:compressor) { Rambling::Trie::Compressor.new }
    let!(:container) { Rambling::Trie::Container.new root, compressor }

    before do
      allow(Rambling::Trie::Container).to receive(:new)
        .and_yield(container)
        .and_return container
    end

    it 'returns a new instance of the trie container' do
      expect(Rambling::Trie.create).to eq container
    end

    context 'with a block' do
      it 'yields the new container' do
        yielded = nil
        Rambling::Trie.create { |trie| yielded = trie }
        expect(yielded).to eq container
      end
    end

    context 'with a filepath' do
      let(:filepath) { 'a test filepath' }
      let(:reader) { double :reader }
      let(:words) { %w(a couple of test words over here) }

      before do
        receive_and_yield = receive(:each_word)
        words.inject(receive_and_yield) do |yielder, word|
          yielder.and_yield word
        end

        allow(reader).to receive_and_yield
        allow(container).to receive :<<
      end

      it 'loads every word' do
        Rambling::Trie.create filepath, reader

        words.each do |word|
          expect(container).to have_received(:<<).with word
        end
      end
    end

    context 'without any reader' do
      let(:filepath) { 'a test filepath' }
      let(:reader) { double :reader, each_word: nil }

      before do
        Rambling::Trie.config do |c|
          c.readers.add :default, reader
          c.readers.default = reader
        end
      end

      it 'defaults to a plain text reader' do
        Rambling::Trie.create filepath, nil

        expect(reader).to have_received(:each_word).with filepath
      end
    end
  end

  describe '.load' do
    let(:root) { Rambling::Trie::Nodes::Raw.new }
    let(:compressor) { Rambling::Trie::Compressor.new }
    let(:container) { Rambling::Trie::Container.new root, compressor }
    let(:serializer) { double :serializer, load: root }
    let(:filepath) { 'a path to a file' }

    it 'returns a new container with the loaded root node' do
      trie = Rambling::Trie.load filepath, serializer
      expect(trie).to eq container
    end

    it 'uses the serializer to load the root node from the given filepath' do
      Rambling::Trie.load filepath, serializer
      expect(serializer).to have_received(:load).with filepath
    end

    context 'without a serializer' do
      let(:marshal_serializer) { double :marshal_serializer, load: nil }
      let(:default_serializer) { double :default_serializer, load: nil }
      let(:yaml_serializer) { double :yaml_serializer, load: nil }

      before do
        Rambling::Trie.config do |c|
          c.serializers.add :default, default_serializer
          c.serializers.add :marshal, marshal_serializer
          c.serializers.add :yml, yaml_serializer
          c.serializers.add :yaml, yaml_serializer

          c.serializers.default = default_serializer
        end
      end

      it 'determines the serializer based on the file extension' do
        Rambling::Trie.load 'test.marshal'
        expect(marshal_serializer).to have_received(:load).with 'test.marshal'

        Rambling::Trie.load 'test.yml'
        expect(yaml_serializer).to have_received(:load).with 'test.yml'

        Rambling::Trie.load 'test.yaml'
        expect(yaml_serializer).to have_received(:load).with 'test.yaml'

        Rambling::Trie.load 'test'
        expect(default_serializer).to have_received(:load).with 'test'
      end
    end

    context 'with a block' do
      it 'yields the new container' do
        yielded = nil

        Rambling::Trie.load filepath, serializer do |trie|
          yielded = trie
        end

        expect(yielded).to eq container
      end
    end
  end

  describe '.dump' do
    let(:filename) { 'a trie' }
    let(:root) { double :root }
    let(:compressor) { double :compressor }
    let(:trie) { Rambling::Trie::Container.new root, compressor }

    let(:marshal_serializer) { double :marshal_serializer, dump: nil }
    let(:yaml_serializer) { double :yaml_serializer, dump: nil }
    let(:default_serializer) { double :default_serializer, dump: nil }

    before do
      Rambling::Trie.config do |c|
        c.serializers.add :default, default_serializer
        c.serializers.add :marshal, marshal_serializer
        c.serializers.add :yml, yaml_serializer

        c.serializers.default = default_serializer
      end
    end

    it 'uses the configured default serializer by default' do
      Rambling::Trie.dump trie, filename
      expect(default_serializer).to have_received(:dump).with root, filename
    end

    context 'when provided with a format' do
      it 'uses the corresponding serializer' do
        Rambling::Trie.dump trie, "#{filename}.marshal"
        expect(marshal_serializer).to have_received(:dump)
          .with root, "#{filename}.marshal"

        Rambling::Trie.dump trie, "#{filename}.yml"
        expect(yaml_serializer).to have_received(:dump)
          .with root, "#{filename}.yml"
      end
    end
  end

  describe '.config' do
    it 'returns the properties' do
      expect(Rambling::Trie.config).to eq Rambling::Trie.send :properties
    end

    it 'yields the properties' do
      yielded = nil
      Rambling::Trie.config { |c| yielded = c }
      expect(yielded).to eq Rambling::Trie.send :properties
    end
  end
end
