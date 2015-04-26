Exquery
=======

A simple Elixir DOM library for building a tree from an HTML string and then selecting elements that lurk within.


### Example

#### select an element with `one/2`
Selecting an `li`  `:tag` with specific attrs using `one/2`
```elixir
"""
<div class="red-fish">
  <ul class="blue-fish">
    <li class="one-fish">Hello</li>
    <li class="two-fish">World</li>
  </ul>
</div>
"""
|> Exquery.tree
|> Exquery.Query.one({:tag, "li", [{"class", "one-fish"}]})

```

This evaluates to:
```elixir
{{:tag, "li", [{"class", "one-fish"}]}, [{:text, "Hello", []}]}
```

#### select all elements with `all/2`
Similarly, you can select all elements using `all/2`
```elixir
"""
<div class="red-fish">
  <ul class="blue-fish">
    <li class="one-fish">Hello</li>
    <li class="two-fish">World</li>
  </ul>
</div>
"""
|> Exquery.tree
|> Exquery.Query.all({:tag, "li", []})
```

This evaluates to:
```elixir
[{{:tag, "li", [{"class", "one-fish"}]}, [{:text, "Hello", []}]},
 {{:tag, "li", [{"class", "two-fish"}]}, [{:text, "World", []}]}]
```

#### select siblings with `before/3` and `next/3`
You can select a sibling using `before/3 and `next/3`
```elixir
"""
<div class="red-fish">
  <ul class="blue-fish">
    <li class="one-fish">Hello</li>
    <li class="two-fish">World</li>
  </ul>
</div>
"""
|> Exquery.tree
|> Exquery.Query.next({:tag, "li", []})
```

This evaluates to:
```elixir
{{:tag, "li", [{"class", "two-fish"}]}, [{:text, "World", []}]}
```

or
```elixir
"""
<div class="red-fish">
  <ul class="blue-fish">
    <li class="one-fish">Hello</li>
    <li class="two-fish">World</li>
  </ul>
</div>
"""
|> Exquery.tree
|> Exquery.Query.before({:tag, "li", [{"class", "two-fish"}]})
```

This evaluates to:
```elixir
{{:tag, "li", [{"class", "one-fish"}]}, [{:text, "Hello", []}]}
```




#### Todo: 
*  Documentation
*  CSS style selections
*  Streaming tokenizer and tree builder
