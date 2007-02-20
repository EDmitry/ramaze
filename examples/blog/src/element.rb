class Page < Controller
  attr_accessor :content
  helper :auth

  def initialize content
    @content = content
  end

  def render
    p :render => content
    %{
<html>
  <head>
    <title>#{@title}</title>
    <link href="/screen.css" type="text/css" rel="stylesheet">
  </head>
  <body>
    #{menu}
    #{sidebar}
    #{content}
  </body>
</html>
    }
  end

  def menu
    %{
    <div id="menu">
      <span id="title">
        <a href="#{R :/}">#{@title || 'Blogging Ramaze'}</a>
      </span>
      <?r if logged_in? ?>
        <span id="login"> #{link R(:logout), :title => 'logout'} </span>
      <?r else ?>
        <span id="login"> #{link R(:login), :title => 'login'} </span>
      <?r end ?>
    </div>
    }
  end

  def sidebar
    entries =
      Entry.all.map do |eid, e|
      %{
        <div>
          #{link R(:/, :view, eid), :title => e.title}
        </div>
      }
      end

    %{
    <div id="sidebar">
      <h1>Recent Entries</h1>
      #{entries}
    </div>
    }
  end
end
