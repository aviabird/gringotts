defmodule Kuber.Hex.Utils do
  defmodule XmlParser do
    require Record
    Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
    Record.defrecord :xmlText,    Record.extract(:xmlText,    from_lib: "xmerl/include/xmerl.hrl")
    
    def scan_text(text) do
      :xmerl_scan.string(String.to_char_list(text))
    end
  
    def parse_xml({ xml, _ }) do
      # single element
      basepath = '/WIRECARD_BXML/W_RESPONSE/W_JOB/CC_TRANSACTION/PROCESSING_STATUS'
      element  = :xmerl_xpath.string(basepath, xml)
      # [content]     = xmlElement(element, :content)
      # value      = xmlText(text, :value)
      # IO.inspect to_string(element)
      # IO.puts "============#{inspect content}======"
      # element
      element
      # # multiple elements
      # elements   = :xmerl_xpath.string('/breakfast_menu//food/name', xml)
      # Enum.each(
      #   elements,
      #   fn(element) ->
      #     [text]     = xmlElement(element, :content)
      #     value      = xmlText(text, :value)
      #     IO.inspect to_string(value)
      #   end
      # )
    end
  end
end