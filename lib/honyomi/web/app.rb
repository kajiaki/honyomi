require 'haml'
require 'honyomi/database'
require 'sinatra'
require 'sinatra/reloader' if ENV['SINATRA_RELOADER']

include Honyomi

set :haml, :format => :html5

configure do
  $database = Database.new
end

get '/' do
  @database = $database

  if @params[:query] && !@params[:query].empty?
    results = @database.search(@params[:query])

    page_entries = results.paginate([["_score", :desc]], :page => 1, :size => 20)
    snippet = results.expression.snippet([["<strong>", "</strong>"]], {html_escape: true, normalize: true, max_results: 10})

    books = {}

    results.each do |page|
      books[page.book.path] = 1
    end

    r = page_entries.map do |page|
      query_plus  = escape "#{@params[:query]} book:#{page.book.id}"
      query_minus = escape "#{@params[:query]} -book:#{page.book.id}"

      <<EOF
  <div class="result">
    <div class="result-header"><a href="/v/#{page.book.id}?page=#{page.page_no}">#{page.book.title}</a> (P#{page.page_no})</div>
    <div class="row result-sub-header">
      <div class="col-xs-6"><a href="/?query=#{query_plus}">Filter+</a> <a href="/?query=#{query_minus}">Filter-</a></div>
    </div>
    <div class="result-body">
      #{snippet.execute(page.text).map {|segment| "<div class=\"result-body-element\">" + segment.gsub("\n", "") + "</div>"}.join("\n") }
    </div>
  </div>
EOF
    end

    @content = <<EOF
<div class="matches">#{books.size} books, #{results.size} pages</div>
#{r.join("\n")}
EOF
  else
    r = @database.books.map { |book|
      <<EOF
<li>#{book.id}: <a href="/v/#{book.id}">#{book.title}</a> (#{book.page_num}P)</li>
EOF
    }.reverse

    @content = <<EOF
<div class="matches">#{@database.books.size} books, #{@database.pages.size} pages.</div>
<div class="result">
  <ul>
#{r.join("\n")}
  </ul>
</div>
EOF
  end

  haml :index
end

post '/search' do
  redirect "/?query=#{escape(params[:query])}"
end

get '/v/:id' do
  @database = $database

  book = @database.books[params[:id].to_i]

  if params[:raw] == '1'
    pages = @database.book_pages(book.id)

    @navbar_href = "#1"
    @navbar_title = book.title

    @content = pages.map { |page|
      <<EOF
<div class="raw-page" id="#{page.page_no}">
  <div class="raw-page-no"><i class="fa fa-file-text-o"></i> <a href="##{page.page_no}">P#{page.page_no}</a></div>
  <pre>#{escape_html page.text}</pre>
</div>
EOF
    }.join("\n")

    haml :raw
  elsif params[:pdf] == '1'
    send_file(book.path, :disposition => 'inline')
  elsif params[:dl] == '1'
    send_file(book.path, :disposition => 'download')
  else
    @navbar_href = ""
    @navbar_title = book.title

    pages = @database.book_pages(book.id)
    file_mb = File.stat(book.path).size / (1024 * 1024)

    if params[:page]
      page = pages[params[:page].to_i]

      @content = <<EOF
<div class="landing-page" id="#{page.page_no}">
  <div class="landing-page-no"><i class="fa fa-file-text-o"></i> P#{page.page_no} &nbsp;&nbsp;&nbsp;
  <a href="/v/#{book.id}?dl=1">Download</a> <span class="result-file-size">(#{file_mb}M)</span>&nbsp;&nbsp;&nbsp;<a href="/v/#{book.id}?pdf=1#page=#{page.page_no}">Pdf</a>&nbsp;&nbsp;&nbsp;<a href="/v/#{book.id}?raw=1##{page.page_no}">Raw</a></div>
  <pre>#{escape_html page.text}</pre>
</div>
EOF
      haml :raw
    else
      @content = <<EOF
<div class="result">
  <div class="matches">#{book.page_num} pages. <a href="/v/#{book.id}?dl=1">Download</a> <span class="result-file-size">(#{file_mb}M)</span>&nbsp;&nbsp;&nbsp;<a href="/v/#{book.id}?pdf=1">Pdf</a>&nbsp;&nbsp;&nbsp;<a href="/v/#{book.id}?raw=1">Raw</a></div>
</div>
EOF
      haml :index
    end

  end
end

