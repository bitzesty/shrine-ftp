require 'shrine'
require 'net/sftp'
require 'down'

class Shrine
  module Storage
    ##
    # The Ftp storage handles uploads to Ftp via FTP using the
    # `shrine-ftp` gem:
    #
    #   gem "shrine-ftp"
    #
    # It is initialized with the following 4 required arguments:
    #
    #   storage = Shrine::Storage::Sftp.new(
    #     host: "ftp.hosturl.com",
    #     user: "username",
    #     password: "yourpassword",
    #     dir: "path/to/upload/files/to"
    #   )
    #
    # It can also take an optional argument `prefix` as the URL or domain
    # to prefix to your file location. This comes in handy when your ftp host
    # and your file prefix url are different, such as if you're using a CDN.
    class Sftp

      # Initializes a storage for uploading to Ftp
      #
      # == Parameters:
      # host::
      #   ftp host
      # user::
      #   ftp username
      # password::
      #   ftp password
      # dir::
      #   directory (will be created if it doesn't exist) to upload files to
      # prefix::
      #   (optional) url hostname if files actually live in a different URL (or are served by CDN). If none is provided, defaults to `host`
      # == Returns:
      # An object that represents the Ftp storage.
      #
      def initialize(host:, user:, password:, dir:, prefix: nil)
        @host = host
        @user = user
        @password = password
        @dir = dir
        @prefix = prefix || host
      end

      def upload(io, id, shrine_metadata: {}, **upload_options)
        path_and_file = build_path_and_file(io)
        Net::SFTP.start(@host, @user, @password) do |sftp|
          sftp.mkdir!(@dir, permissions: 0755)
          sftp.put_file(path_and_file, id)
        end
      end

      def url(id, **options)
        [@host, @dir, id].join('/')
      end

      # Downloads the file to a buffer
      def open(id)
        Net::SFTP.start(@host, @user, @password) do |sftp|
          sftp.download!(url(id))
        end
      end

      # Returns a boolean based on whether the file exists/
      def exists?(id)
        Net::SFTP.start(@host, @user, @password) do |sftp|
          sftp.stat!(url(id))
        end
      end

      # Deletes the file via SFTP.
      def delete(id)
        Net::SFTP.start(@host, @user, @password) do |sftp|
          sftp.remove!(url(id))
        end
      end

      def to_s
        "#<Shrine::Storage::Sftp @host='#{@host}'>"
      end

      private

      def build_path_and_file(io)
        if io.is_a?(UploadedFile) && defined?(Storage::FileSystem) && io.storage.is_a?(Storage::FileSystem)
          return "#{io.storage.directory.to_s}/#{io.id}"
        else
          return io
        end
      end
    end
  end
end
