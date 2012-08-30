object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Tags!" }
node(:total) { @tags.count }
node(:startIndex) { 1 }
node(:pageSize) { @tags.count }
node(:currentPage) { 1 }
node(:pages) { 1 }
node(:results) do
    @tags.map { |r|
      {
        id: r.tag_id,
        title: r.title,
        fields: {
          type: r.tag_type,
          description: 'tbd', #r.description,
          parent: 'tbd' #r.parent_id
        }
      }
    }
end
