module BrowserHelper

  def placeholder(label=nil)
    "placeholder='#{label}'" if platform == 'apple'
  end

  def platform
    System::get_property('platform').downcase
  end

  def selected(option_value,object_value)
    "selected=\"yes\"" if option_value == object_value
  end

  def checked(option_value,object_value)
    "checked=\"yes\"" if option_value == object_value
  end


  def hash_to_xml(tag,fields,values)
    xml_response = "<#{tag}>"
    values.each do |x,y|
      fields.each do |f|
        if f == x
          xml_response += "<#{x}>"
          xml_response += y
          xml_response += "</#{x}>"
        end
      end
    end
    xml_response += "</#{tag}>"
    return xml_response
  end

  def get_date(date)
    year = date[0,4]
    month = date[5,2]
    day = date[8,2]
    months = {"01" => "Jan", "02" => "Feb", "03" => "Mar", "04" => "Apr", "05" => "May", "06" => "Jun",
              "07" => "Jul", "08" => "Aug", "09" => "Sep", "10" => "Oct", "11" => "Nov", "12" => "Dec"}
    months.each { |num, name|
      case month
      when num
        month = name
      end
    }
    return "#{day.to_i} #{month} #{year}"
  end

end