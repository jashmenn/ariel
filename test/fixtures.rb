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
<ol>
<li><l:comment>Title:<l:title>Great example</l:title>
<l:author>Adoring fan</l:author>
<l:body>Always love reading your examples, keep up the great work.</l:body>
</l:comment></li>
<li><l:comment>Title: <l:title>Some advice</l:title>
<l:author>Wise old man</l:author>
<l:body>Keep your friends close and your enemies closer.</l:body>
</l:comment></li></l:comment_list>
EOS

  @@labeled_document_with_list_structure = Ariel::Node::Structure.new do |r|
    r.item :title
    r.item :body
    r.item :comment_list do |c|
      c.list_item :comment do |d|
        d.item :author
        d.item :body
      end
    end
  end

  title_ruleset=Ariel::RuleSet.new [Ariel::Rule.new([[":"]], :forward)], [Ariel::Rule.new([["love", "I"]], :back)]
  body_ruleset=Ariel::RuleSet.new [Ariel::Rule.new([["example"]], :forward)], [Ariel::Rule.new([["Comments"]], :back)]
  c_list_ruleset=Ariel::RuleSet.new [Ariel::Rule.new([["be", "."]], :forward)], [Ariel::Rule.new([], :back)]
  comment_ruleset=Ariel::RuleSet.new [Ariel::Rule.new([["<li>"]], :forward, true)], [Ariel::Rule.new([["</li>"]], :back, true)]
  
  s=@@labeled_document_with_list_structure
  s.title.ruleset=title_ruleset
  s.body.ruleset=body_ruleset
  s.comment_list.ruleset=c_list_ruleset
  s.comment_list.comment.ruleset=comment_ruleset

  @@labeled_addresses=Array.new(4) {Ariel::TokenStream.new}
  @@labeled_addresses[0].tokenize("513 Pico <b>Venice</b>, Phone: 1-<b>800</b>-555-1515")
  @@labeled_addresses[0].set_label_at 36
  @@labeled_addresses[1].tokenize("90 Colfax, <b> Palms </b>, Phone: (818) 508-1570")
  @@labeled_addresses[1].set_label_at 35
  @@labeled_addresses[2].tokenize("523 1st St., <b> LA </b>, Phone: 1-<b>888</b>-578-2293")
  @@labeled_addresses[2].set_label_at 38
  @@labeled_addresses[3].tokenize("403 La Tijera, <b> Watts </b>, Phone: (310) 798-0008")
  @@labeled_addresses[3].set_label_at 39

  # This example is from the STALKER paper, it suggests that SkipTo('<p><i>')
  # would extract the start of the list, and the rules SkipTo '<i>' and SkipTo
  # '</i>' would locate the start and end of each list item. If the first found
  # end_loc and before the first start_loc, it should be assumed all tokens from
  # 0...end_loc are one item.
  @@unlabeled_restaurant_example=<<EOS
<p> Name: <b> Yala </b><p> Cuisine: Thai <p><i>
4000 Colfax, Phoenix, AZ 85258 (602) 508-1570
</i><br><i>
523 Vernon, Las Vegas, NV 89104 (702) 578-2293
</i><br><i>
403 Pico, LA, CA 90007 (213) 798-0008
</i>
EOS

end
