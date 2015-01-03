module LRUGHelpers
  def page_title(for_page = current_page)
    yield_content(:title) || for_page.data.title
  end

  def unless_url(matches, &html_block)
    unless current_resource.url =~ matches
      concat_content(capture_html &html_block)
    end
  end

  def if_url(matches, &html_block)
    if current_resource.url =~ matches
      concat_content(capture_html &html_block)
    end
  end

  def with_page(slug_match, &html_block)
    page = sitemap.where(:slug => slug_match).first
    if page
      concat_content(capture_html page, &html_block)
    end
  end

  def show_sponsors(for_page = current_page)
    partial "sponsors", locals: { for_page: for_page }
  end

  def link_to_most_recent(category)
    meeting = most_recent(category)
    link_to meeting.data.title, meeting
  end

  def most_recent(category)
    case category
    when 'meeting'
      meeting_pages.first
    when 'book_review'
      book_reviews.first
    end
  end

  def meeting_pages
    sitemap
      .resources
      .select { |page| page_has_data?(page, status: 'Published', category: "meeting") }
      .sort_by { |page| page.data.published_at }
      .reverse
  end

  def book_reviews
    sitemap
      .resources
      .select { |page| page_has_data?(page, status: 'Published', category: 'book-review') }
      .sort_by { |page| page.data.published_at }
      .reverse
  end

  def podcast_episodes
    sitemap
      .resources
      .select { |page| page_has_data?(page, status: 'Published', category: 'podcast') }
      .sort_by { |page| page.data.published_at }
      .reverse
  end

  def page_has_data?(page, args)
    args.all? do |key, value|
      page.data[key.to_s] == value
    end
  end

  def content_part_exists?(part_name, page, inherit: false)
    find_page_part(part_name, page, inherit: inherit).present?
  end

  def render_content_part(part_name, page, inherit: false)
    part = find_page_part(part_name, page, inherit: inherit)
    if part
      if part['filter'].present?
        Tilt.new(part['filter']) do
          Tilt.new('.erb') do
            part['content']
          end.render(self, page: page)
        end.render(self, page: page)
      else
        part['content']
      end
    else
      ''
    end
  end

  private
  def find_page_part(part_name, page, inherit: false)
    if page.data.parts? && page.data.parts.has_key?(part_name)
      page.data.parts[part_name]
    elsif inherit && page.parent.present?
      find_page_part(part_name, page.parent, inherit: inherit)
    else
      nil
    end
  end

  public
  def date_format(date, format)
    date.strftime(format) unless date.nil?
  end

  def rfc_1123_date(date)
    date.rfc2822 unless date.nil?
  end

  def render_markdown(md)
    Tilt['markdown'].new do
      md
    end.render
  end

  def meeting_calendar_link
    render_markdown(
      %{<span class="calendar-link">[![Calendar subscription](http://assets.lrug.org/images/calendar_down.gif) Meeting Calendar](/meeting-calendar)</span>}
    )
  end
end
