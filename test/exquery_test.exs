defmodule ExqueryTest do
  use ExUnit.Case
  alias Exquery, as: E
  
  test "can tokenize basic html" do
    assert E.tokenize("<div>hello >   </div>") ==
    [
      {:open_tag, "div", []},
      {:text, "hello >   ", []},
      {:close_tag, "div", []}
    ]

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

  test "can parse a K:V attribute string" do
    assert E.to_attributes("class='hel\"lo'", []) == {
      "", 
      [{"class", "hel\"lo"}]
    }

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

    assert E.to_attributes("class=foo id=bar something=else", []) == {
      "",
      [
        {"something", "else"},
        {"id", "bar"},
        {"class", "foo"}
      ]
    }

    assert E.to_attributes("class=\"foo\"id='bar' something='else>", []) == {
      ">",
      [
        {"something", "else"},
        {"id", "bar"},
        {"class", "foo"}
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


end
