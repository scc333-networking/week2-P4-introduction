-- file: enable-checkbox.lua
function Str (s)
  if s.text == '☐' then
    return pandoc.RawInline('html', '<input type="checkbox">')
  elseif s.text == '☑' then
    return pandoc.RawInline('html', '<input type="checkbox" checked>')
  end
end
