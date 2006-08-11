module Fixtures
  @@labeled_document = <<EOS
Title: <l:title>The test of the Century</l:title>
<l:content><b>Excerpt</b>: <i><l:excerpt>A look back at what could be considered the greatest ever test.</l:excerpt></i>
<l:body>There was once a test designed to assess whether apply_extraction_tree_on worked.</l:body></l:content>
EOS
  @@labeled_document_structure = Ariel::Node::Structure.new do |r|
    r.item :title
    r.item :content do |c|
      c.item :excerpt
      c.item :body
    end
  end
  @@unlabeled_document=<<EOS
Title: The test of the Century
<b>Excerpt</b>: <i>A look back at what could be considered the greatest ever test.</i>
There was once a test designed to assess whether apply_extraction_tree_on worked.
EOS
  # Document with nested labels with clashing names. i.e. a label at the top
  # level as well as a label lower down in the tree that has the same label
  # name.
  @@labeled_document_with_list=<<EOS
Title: <l:title>Another example</l:title>
<l:body>I love to write examples, you love to read them, ruby loves to process them.
In conclusion, we're has happy as can be.</l:body>
<l:comment_list>Comments:
<l:comment>Title:<l:title>Great example</l:title>
<l:author>Adoring fan</l:author>
<l:body>Always love reading your examples, keep up the great work.</l:body>
</l:comment></l:comment_list>
EOS

  @@labeled_addresses=Array.new(4) {Ariel::TokenStream.new}
  @@labeled_addresses[0].tokenize("513 Pico <b>Venice</b>, Phone: 1-<b>800</b>-555-1515")
  @@labeled_addresses[0].set_label_at 36
  @@labeled_addresses[1].tokenize("90 Colfax, <b> Palms </b>, Phone: (818) 508-1570")
  @@labeled_addresses[1].set_label_at 35
  @@labeled_addresses[2].tokenize("523 1st St., <b> LA </b>, Phone: 1-<b>888</b>-578-2293")
  @@labeled_addresses[2].set_label_at 38
  @@labeled_addresses[3].tokenize("403 La Tijera, <b> Watts </b>, Phone: (310) 798-0008")
  @@labeled_addresses[3].set_label_at 39

end
