# encoding: utf-8

class Image < ::HTML::Proofer::Checkable

  SCREEN_SHOT_REGEX = /Screen(?: |%20)Shot(?: |%20)\d+-\d+-\d+(?: |%20)at(?: |%20)\d+.\d+.\d+/

  def valid_alt_tag?
    @ignore_alt || @alt and !@alt.empty?
  end

  def terrible_filename?
    @src =~ SCREEN_SHOT_REGEX
  end

  def src
    @src unless @src.nil? || @src.empty?
  end

  def missing_src?
    !src
  end

  def ignore_alt
    unless @check.additional_alt_ignores.empty?
      @check.additional_alt_ignores.each do |alt_ignore|
        if alt_ignore.is_a? String
          return true if alt_ignore == @src
        elsif alt_ignore.is_a? Regexp
          return true if alt_ignore =~ @src
        else
          return false
        end
      end
    end
  end

end

class Images < ::HTML::Proofer::Checks::Check
  def run
    @html.css('img').each do |i|
      img = Image.new i, "image", self

      # screenshot filenames should return because of terrible names
      next self.add_issue "image has a terrible filename (#{img.src})" if img.terrible_filename?

      # does the image exist?
      if img.missing_src?
        self.add_issue "image has no src attribute"
      elsif img.remote?
        next if img.ignore?
        add_to_external_urls img.src
      else
        next if img.ignore?
        self.add_issue("internal image #{img.src} does not exist") unless img.exists?
      end

      # check alt tag
      self.add_issue "image #{img.src} does not have an alt attribute" unless img.valid_alt_tag?
    end

    external_urls
  end
end
