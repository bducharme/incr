module Incr
  module Command
    class Mix
      MIXFILE_FILENAME = 'mix.exs'.freeze

      def initialize(args)
        @segment = args[0]
      end

      def execute
        file_content = parse_content(MIXFILE_FILENAME)
        if file_content == nil
          return
        end

        file_version = file_content.match(/version:\W*\"(\d*.\d*.\d*)",/)[1]
        old_version = SemVersion.new(file_version)
        new_version = Incr::Service::Version.increment_segment(old_version, @segment)
        Incr::Service::FileHelper.replace(MIXFILE_FILENAME, version_pattern(old_version.to_s), version_pattern(new_version.to_s))

        puts "v#{new_version.to_s}"

        git = Incr::Service::Git.new('.')
        git.add(MIXFILE_FILENAME)
        oid = git.commit(new_version.to_s)
        git.tag("v#{new_version.to_s}", oid)
      end

      private

      def parse_content(filename)
        if !File.exist?(filename)
          STDERR.puts("[Err] '#{filename}' not found.")
          return nil
        end

        IO.read(filename)
      end

      def version_pattern(version)
        "version: \"#{version}\""
      end
    end
  end
end
