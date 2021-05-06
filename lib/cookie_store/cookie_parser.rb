require 'stream_parser'

class CookieStore::CookieParser

  include StreamParser

  NUMERICAL_TIMEZONE = /[-+]\d{4}\Z/
  
  def parse(set_cookie_value)
    cookie = {attributes: {}}
    current_attribute = nil
    
    @stack = [:cookie_name]
    while !eos?
      case @stack.last
      when :cookie_name
        scan_until(/\s*=\s*/)
        if match == '='
          @stack.pop
          @stack << :cookie_value
          cookie[:key] = pre_match
        end
      when :cookie_value
        scan_until(/\s*['";]/)
        if match.end_with?('"')
          @stack.pop
          @stack << :cookie_value_double_quoted
        elsif match.end_with?("'")
          @stack.pop
          @stack << :cookie_value_single_quoted
        else
          gobble(/\s*/)
          @stack.pop
          @stack << :cookie_attributes
          cookie[:value] = pre_match
        end
      when :cookie_value_double_quoted
        scan_until(/(?<=\\)"/)
        if match == '"'
          cookie[:value] = pre_match
          @stack.pop
          @stack << :cookie_attributes
        else
          raise Net::HTTPHeaderSyntaxError.new(%q{Invalid Set-Cookie header format: unbalanced quotes (")})
        end
      when :cookie_value_single_quoted
        scan_until(/(?<=\\)'/)
        if match == "'"
          cookie[:value] = pre_match
          @stack.pop
          @stack << :cookie_attributes
        else
          raise Net::HTTPHeaderSyntaxError.new(%q{Invalid Set-Cookie header format: unbalanced quotes (')})
        end
      when :cookie_attributes
        # RFC 2109 4.1, Attributes (names) are case-insensitive
        scan_until(/([=;]\s*|\Z)/)
        if match.start_with?('=')
          current_attribute = pre_match.downcase.gsub('-','_').to_sym
          @stack << if next_char == '"'
            :cookie_attribute_value_double_quoted
          elsif next_char == "'"
            :cookie_attribute_value_single_quoted
          else
            :cookie_attribute_value
          end
        else
          cookie[:attributes][pre_match.downcase.gsub('-','_').to_sym] = true
        end
      when :cookie_attribute_value
        scan_until(/(;\s*|\Z)/)
        cookie[:attributes][current_attribute] = normalize_attribute_value(current_attribute, pre_match)
        @stack.pop
      when :cookie_attribute_value_double_quoted
        scan_until(/"\s*(;\s*|\Z)/)
        cookie[:attributes][current_attribute] = normalize_attribute_value(current_attribute, pre_match)
        @stack.pop
      when :cookie_attribute_value_single_quoted
        scan_until(/'\s*(;\s*|\Z)/)
        cookie[:attributes][current_attribute] = normalize_attribute_value(current_attribute, pre_match)
        @stack.pop
      end
    end
    
    cookie
  end
  
  def normalize_attribute_value(key, value)
    case key
    when :domain
      if value =~ URI::REGEXP::PATTERN::IPV4ADDR
        value
      elsif value =~ URI::REGEXP::PATTERN::IPV6ADDR
        value
      else
        # As per RFC2965 if a host name contains no dots, the effective host
        # name is that name with the string .local appended to it.
        value = "#{value}.local" if !value.include?('.')
        (value.start_with?('.') ? value : ".#{value}").downcase
      end
    when :expires
      if value.include?('-') && !value.match(NUMERICAL_TIMEZONE)
        options[:expires] = DateTime.strptime(value, '%a, %d-%b-%Y %H:%M:%S %Z')
      else
        options[:expires] = DateTime.strptime(value, '%a, %d %b %Y %H:%M:%S %Z')
      end
    when :max_age
      value.to_i
    when :port#s!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      value.split(',').map(&:to_i)
    when :version
      value.to_i
    end
  end
  
end
