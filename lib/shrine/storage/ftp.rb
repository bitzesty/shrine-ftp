require 'shrine'
require 'net/ftp'

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
    #   storage = Shrine::Storage::Ftp.new(
    #     host: "ftp.hosturl.com",
    #     user: "username",
    #     passwd: "yourpassword",
    #     dir: "path/to/upload/files/to"
    #   )
    #
    # It can also take an optional argument `prefix` as the URL or domain
    # to prefix to your file location. This comes in handy when your ftp host
    # and your file prefix url are different, such as if you're using a CDN.
    class Ftp

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

      def connection
        Net::FTP.new(@host, connection_params)
      end

      def connection_params
        {
          port:     port,
          ssl:      ssl_context_params,
          passive:  true,
          username: @user,
          password: @password
        }
      end

      # Starts an FTP connection, changes to the appropriate directory (or creates it),
      # and uses .putbinaryfile() to upload the file.
      def upload(io, id, shrine_metadata: {}, **upload_options)
        path_and_file = build_path_and_file(io)
        ftp = connection
        change_or_create_directory(ftp)
        ftp.putbinaryfile(path_and_file, id)
        ftp.close
      end

      def url(id, **options)
        [@host, @dir, id].join('/')
      end

      # Downloads the file
      def open(id)
        ftp = connection
        change_or_create_directory(ftp)
        ftp.getbinaryfile(path_and_file, id)
        ftp.close
      end

      def exists?(id)
        ftp = connection
        begin
          ftp.size(id)
        rescue FTPReplyError => e
          reply = e.message
          err_code = reply[0,3].to_i
          unless err_code == 500 || err_code == 502
            # other problem, raise
            raise
          end
          # fallback solution
        end
        ftp.close
        true
      end

      # Deletes the file via FTP.
      def delete(id)
        if exists?(id)
          ftp = connection
          change_or_create_directory(ftp)
          ftp.delete(id)
          ftp.close
          return true
        end
        return false
      end

      def to_s
        "#<Shrine::Storage::Ftp @host='#{@host}'>"
      end

      private

      def build_path_and_file(io)
        if io.is_a?(UploadedFile) && defined?(Storage::FileSystem) && io.storage.is_a?(Storage::FileSystem)
          return "#{io.storage.directory.to_s}/#{io.id}"
        else
          return io
        end
      end

      def change_or_create_directory(ftp)
        begin
          ftp.chdir(@dir)
        rescue Net::FTPPermError
          ftp.mkdir(@dir)
          ftp.chdir(@dir)
        end
      end
    end
  end
end
