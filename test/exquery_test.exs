defmodule ExqueryTest do
  use ExUnit.Case
  alias Exquery, as: E
  

  def foo(<<head::binary-size(1), rest::binary>>) when head == "f" do
    :ok
  end
  def foo(o) do
    o
  end

  test "foo" do
    IO.inspect foo("foo")
  end


  test "can tokenize basic html" do
    assert E.tokenize("<div>hello >   </div>") ==
    [
      {:open_tag, "div", []},
      {:text, "hello >   ", []},
      {:close_tag, "div", []}
    ]
  end

  test "can parse nested html" do

    assert E.tokenize(String.strip("""
      <div>hello <italic>world</italic></div>
    """)) == [
      {:open_tag, "div", []},
        {:text, "hello ", []},
        {:open_tag, "italic", []},
          {:text, "world", []},
        {:close_tag, "italic", []},
      {:close_tag, "div", []}
    ]

    assert E.tokenize(String.strip("""
      <div> h e l l o
        <ul>
          <li>foo</li>
          <li>bar</li>
        </ul>
      </div>
    """)) == [
      {:open_tag, "div", []}, 
        {:text, " h e l l o\n    ", []}, 
          {:open_tag, "ul", []},
            {:open_tag, "li", []}, 
              {:text, "foo", []}, 
            {:close_tag, "li", []},
            {:open_tag, "li", []}, 
              {:text, "bar", []}, 
            {:close_tag, "li", []},
          {:close_tag, "ul", []}, 
        {:close_tag, "div", []}
      ]
  end

  test "can parse a comment" do
    assert E.tokenize(String.strip("""
      <div>
        <!-- i am a comment -->
      </div>
    """)) == [
      {:open_tag, "div", []},
        {:comment, " i am a comment ", []},
      {:close_tag, "div", []}
    ]
  end

  test "can parse an attribute string" do
    assert E.to_attributes("class='hel\"lo'", []) == {
      "", 
      [{"class", "hel\"lo"}]
    }
  end

  test "can parse a single and double quote attribute string" do
    assert E.to_attributes(
      "class='hello world' id=\"foo-bar\"", 
      []
    ) == {
      "",
      [
        {"id", "foo-bar"},
        {"class", "hello world"}
      ]
    }
  end

  test "can parse an unquoted attribute string" do
    assert E.to_attributes("class=foo id=bar something=else", []) == {
      "",
      [
        {"something", "else"},
        {"id", "bar"},
        {"class", "foo"}
      ]
    }
  end

  test "can parse an attribute string without space delimiting" do
    assert E.to_attributes("class=\"foo\"id='bar' something='else>", []) == {
      ">",
      [
        {"something", "else"},
        {"id", "bar"},
        {"class", "foo"}
      ]
    }
  end

  test "can parse a key attribute string with no values, line break delimited" do
    assert E.to_attributes(
      " 
      selected 
      checked", 
      []
    ) == {
      "",
      [
        {"checked", ""},
        {"selected", ""},
      ]
    }
  end

  test "can parse a key attribute string space delimited, some with values" do
    assert E.to_attributes(
      "class='hello world' selected checked", 
      []
    ) == {
      "",
      [
        {"checked", ""},
        {"selected", ""},
        {"class", "hello world"}
      ]
    }
  end

  test "can parse attributes" do
    assert E.tokenize(String.strip("""
      <a href='google dot com'>hello</a>
    """)) === [
      {:open_tag, "a", [{"href", "google dot com"}]},
        {:text, "hello", []},
      {:close_tag, "a", []}
    ]
  end

  test "can parse a doctype" do
    assert E.tokenize(String.strip("""
      <!DOCTYPE html>
      <html>
        <body>
        </body>
      </html>
    """)) == [
      {:doctype, "DOCTYPE", [{"html", ""}]},
      {:open_tag, "html", []},
        {:open_tag, "body", []},
        {:close_tag, "body", []},
      {:close_tag, "html", []}
    ]
  end

  test "can parse a weird doctype" do
    assert E.tokenize(String.strip("""
      <!DOCTYPE

          html
      >
      <html>
        <body>
        </body>
      </html>
    """)) == [
      {:doctype, "DOCTYPE", [{"html", ""}]},
      {:open_tag, "html", []},
        {:open_tag, "body", []},
        {:close_tag, "body", []},
      {:close_tag, "html", []}
    ]
  end


  test "can handle embedded CSS" do
    assert E.tokenize(String.strip("""
      <!DOCTYPE html>
      <html>
        <body>
          <style type="text/css">
            .foo bar {
              border: 1px solid green;
            }

            .bar>baz {
              position:relative;
            }

            /* </style> */

            .bar > baz {
              position: fixed !important;
            }
          </style>
        </body>
      </html>
    """)) == [
      {:doctype, "DOCTYPE", [{"html", ""}]}, 
      {:open_tag, "html", []},
        {:open_tag, "body", []}, 
          {:open_style, "", [{"type", "text/css"}]},
            {:css, "\n        .foo bar {\n          border: 1px solid green;\n        }\n\n        .bar>baz {\n          position:relative;\n        }\n\n        /* </style> */\n\n        .bar > baz {\n          position: fixed !important;\n        }\n      ", []}, 
          {:close_style, "", []}, 
        {:close_tag, "body", []},
      {:close_tag, "html", []}]
  end


end
