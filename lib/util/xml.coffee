exports.parse = (xmlString) ->
  xml = null
  # IE
  if window.ActiveXObject?
    try
      xml = new ActiveXObject 'Microsoft.XMLDOM'
      xml.async = false
      xml.loadXML xmlString
    catch error
      xml = null
  # Other browsers
  else if window.DOMParser?
    try
      parser = new DOMParser()
      xml = parser.parseFromString xmlString, 'text/xml'
    catch error
      xml = null
  xml
