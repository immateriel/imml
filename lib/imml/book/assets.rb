require 'imml/book/primitives'
module IMML
  module Book
    class Asset < Entity
      include StoreCheckMethods
      attr_accessor :mimetype, :url, :checksum, :size, :last_modified
      attr_accessor :uid # 201

      def parse(node)
        super
        @mimetype=node["mimetype"]
        @size=node["size"]
        @last_modified=node["last_modified"]
        @checksum=node["checksum"]
        @url=node["url"]
      end

      def self.create(mimetype, size, last_modified=nil, checksum=nil, url=nil, uid=nil)
        asset=self.new
        asset.mimetype=mimetype
        asset.size=size
        asset.last_modified=last_modified
        asset.checksum=checksum
        asset.url=url
        asset.uid=uid
        asset
      end

      def write(xml)
        if self.version.to_i > 200
          if @unsupported
            @attributes[:unsupported]=@unsupported
          end
          if @uid
            @attributes[:uid]=@uid
          end
          self.write_score(xml)
        else
          super
        end

        if @mimetype
          @attributes[:mimetype]=@mimetype
        end
        if @size
          @attributes[:size]=@size
        end
        if @last_modified
          @attributes[:last_modified]=@last_modified
        end
        if @checksum
          @attributes[:checksum]=@checksum
        end
        if @url
          @attributes[:url]=@url
        end
      end

      def check_file(local_file)
        true
      end
    end

    class Cover < Asset
      def write(xml)
        super
        xml.cover(self.attributes)
      end

      # Wget needed - use curl instead ?
      def check_file(local_file)
#        Immateriel.info binding, @url
        uniq_str=Digest::MD5.hexdigest("#{@url}:#{local_file}")
        uri = URI.parse(@url)
        fn="/tmp/#{uniq_str}_"+Digest::MD5.hexdigest(File.basename(uri.path))+File.extname(uri.path)
        self.class.download(@url, fn)
        if File.exists?(fn)
          check_result=self.class.check_image(fn, local_file, uniq_str)
          FileUtils.rm_f(fn)
          if check_result
            true
          else
            false
          end
        else
          false
        end
      end

      private
      def self.check_image(img1, img2, uniq_str, cleanup=true)
        if system("which perceptualdiff > /dev/null")
          self.check_image_perceptualdiff_fork(img1, img2, uniq_str, cleanup)
        else
          self.check_image_imagemagick(img1, img2, uniq_str, cleanup)
        end
      end

      def self.download(url, fn)
        if system("which wget > /dev/null")
          self.download_wget(url, fn)
        else
          self.download_curl(url, fn)
        end
      end

      def self.download_wget(url, fn)
        system("wget -q #{Shellwords.escape(url)} -O #{fn}")
      end

      def self.download_curl(url, fn)
        system("curl -s -o #{fn} #{Shellwords.escape(url)}")
      end

      # https://github.com/immateriel/perceptualdiff
      def self.check_image_perceptualdiff_fork(img1, img2, uniq_str, cleanup=true)
        system("perceptualdiff #{img1} #{img2} --scale --luminance-only --threshold 0.1")
      end

      # ImageMagick needed
      def self.check_image_imagemagick(img1, img2, uniq_str, cleanup=true)
        nsec="%10.9f" % Time.now.to_f
        tmp1="/tmp/check_image_#{nsec}_#{uniq_str}_tmp1.png"
        # on supprime le transparent
        conv1=`convert #{img1} -trim +repage -resize 64 #{tmp1}`
        if File.exists?(tmp1)
          # on recupere la taille
          size1=`identify #{tmp1}`.chomp.gsub(/.*[^\d](\d+x\d+)[^\d].*/, '\1').split("x").map { |v| v.to_i }

          tmp2="/tmp/check_image_#{nsec}_#{uniq_str}_tmp2.png"
          # on convertit l'image deux dans la taille de l'image un
          conv2=`convert #{img2} -trim +repage -resize #{size1.first}x#{size1.last}\\! #{tmp2}`

          if File.exists?(tmp2)
            tmp3="/tmp/check_image_#{nsec}_#{uniq_str}_tmp3.png"
            # on compare
            result=`compare -dissimilarity-threshold 1 -metric mae #{tmp1} #{tmp2} #{tmp3} 2>/dev/stdout`.chomp
            if cleanup
              FileUtils.rm_f(tmp1)
              FileUtils.rm_f(tmp2)
              FileUtils.rm_f(tmp3)
            end
            r=result.gsub(/.*[^\(]\((.*)\).*/, '\1').to_f
            r < 0.25
          else
            false
          end
        else
          false
        end
      end
    end

    class ChecksumAsset < Asset
      def check_file(local_file)
        check_checksum(local_file)
      end

      # ZIP needed
      def calculate_checksum(local_file)
        case @mimetype
          when /epub/
            Digest::MD5.hexdigest(`unzip -p #{local_file}`)
          else
            Digest::MD5.hexdigest(File.read(local_file))
        end

      end

      def set_checksum(local_file)
        @checksum=self.calculate_checksum(local_file)
      end

      def check_checksum(local_file)
        @checksum == self.calculate_checksum(local_file)
      end
    end

    class Extract < ChecksumAsset
      def write(xml)
        super
        xml.extract(self.attributes)
      end

    end

    class Full < ChecksumAsset
      def write(xml)
        super
        xml.full(self.attributes)
      end
    end

    class Assets < IMML::Object
      attr_accessor_with_version :cover, :extracts, :fulls

      def initialize
        @extracts=EntityCollection.new
        @fulls=EntityCollection.new
      end

      def attach_version v
        @extracts.version = v
        @fulls.version = v
      end

      def self.create
        Assets.new
      end

      def parse(node)
        node.children.each do |child|
          case child.name
            when "cover"
              self.cover=Cover.new
              @cover.parse(child)
            when "extract"
              extract=Extract.new
              extract.parse(child)
              self.extracts << extract
            when "full"
              full=Full.new
              full.parse(child)
              self.fulls << full
            else
              # unknown
          end
        end
      end

      def write(xml)
        xml.assets {
          if self.cover
            self.cover.write(xml)
          end

          self.extracts.each do |e|
            e.write(xml)
          end

          self.fulls.each do |f|
            f.write(xml)
          end
        }
      end

    end

  end
end
