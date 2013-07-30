require 'mechanize'
require 'logger'
require 'pry'
require 'zip/zip'

class GetKinokoFry
  attr_accessor :agent, :first_page, :chapter_markers, :previous_url

  def initialize()
    @agent = Mechanize.new
    @agent.log = Logger.new "mech.log"
    @agent.user_agent_alias = 'Mac Safari'
  end

  def start_download
    # Start with first page of first Chapter
    page = @agent.get("http://kinokofry.com/archive/kinokofry-007/")
    puts @agent.current_page().uri()

    keep_going = true
    current_chapter = 1
    page_cursor = 1
    while keep_going
      page = @agent.current_page()
      if page_cursor % 25 == 0
        zip_previous_chapter(current_chapter)
        current_chapter = current_chapter + 1
        puts "Chapter switched to -> " + current_chapter.to_s
      end
      comic_url = page.search("//img[contains(@src,'webcomic')]").first.attributes["src"].to_s
      image_name = comic_url.split('/')[-1]
      @agent.get("#{comic_url}").save("#{chapter_directory(current_chapter)}/#{image_name}")
      puts "Currently Downloading: #{current_chapter}"
      puts "Downloading comic address: #{comic_url}"

      next_link = page.link_with(:text => /Next.*/)
      if next_link
        next_url = next_link.href
        if @previous_url == next_url
          comic_url = page.search("//img[contains(@src,'webcomic')]").first.attributes["src"].to_s
          image_name = comic_url.split('/')[-1]
          @agent.get("#{comic_url}").save("#{chapter_directory(current_chapter)}/#{page_cursor}_#{image_name}")
          puts "Currently Downloading: #{current_chapter}"
          puts "Downloading comic address: #{comic_url}"
          zip_previous_chapter(current_chapter)
          keep_going = false
        end
        next_page = @agent.get(next_url)
        @previous_url = next_url
      else
        zip_previous_chapter(current_chapter)
        keep_going = false
      end
      page_cursor = page_cursor + 1
    end
  end

  def chapter_directory(chapter_id)
    "kinokofry_comics/chapter_#{chapter_id}"
  end

  def zip_file_path(chapter_id)
    directory_name = "saved_comics"
    unless File.directory?(directory_name)
      FileUtils.mkdir_p(directory_name)
    end
    "#{directory_name}/chapter_#{chapter_id}.cbz"
  end

  def zip_previous_chapter(chapter_id)
    directory = chapter_directory(chapter_id)
    zipfile_name = zip_file_path(chapter_id)
    if File.exist?(zipfile_name)
      File.delete(zipfile_name)
    end
    Zip::ZipFile.open(zipfile_name, 'w') do |zipfile|
      Dir["#{directory}/**/**"].reject{|f|f==zipfile_name}.each do |file|
        zipfile.add(file.sub(directory+'/',''),file)
      end
    end
  end

  class << self
    def new_download()
      scary_downloader = self.new()
      scary_downloader.start_download
    end
  end

end

GetKinokoFry.new_download()

exit
