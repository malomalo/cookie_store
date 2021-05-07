require 'stream_parser'

class CookieStore::CookieParser

  include StreamParser
    
  NUMERICAL_TIMEZONE = /[-+]\d{4}\Z/
  
  def parse
    cookie = {attributes: {}}
    
    @stack = [:cookie_name]
    while !eos?
      case @stack.last
      when :cookie_name
        scan_until(/\s*=\s*/)
        if match == '='
          @stack << :cookie_value
          cookie[:key] = pre_match
        end
      when :cookie_value
        scan_until(/\s*(['";]\s*|\Z)/)
        if match.strip == '"' || match.strip == "'"
          cookie[:value] = quoted_value(match.strip)
          @stack.pop
          @stack << :cookie_attributes
        elsif match
          cookie[:value] = pre_match
          @stack.pop
          @stack << :cookie_attributes
        end
      when :cookie_attributes
        # RFC 2109 4.1, Attributes (names) are case-insensitive
        scan_until(/[,=;]\s*/)
        if match&.start_with?('=')
          key = normalize_key(pre_match)
          scan_until(key == :expires ? /\s*((?<!\w{3}),|['";])\s*/ : /\s*(['";,]\s*|\Z)/)
          if match =~ /["']\s*\Z/
            cookie[:attributes][key] = normalize_attribute_value(key, quoted_value(match.strip))
          elsif match =~ /,\s*\Z/
            cookie[:attributes][key] = normalize_attribute_value(key, pre_match)
            yield(cookie)
            cookie = {attributes: {}}
            @stack.pop
          else
            cookie[:attributes][key] = normalize_attribute_value(key, pre_match)
          end
        elsif match&.start_with?(',')
          yield(cookie)
          cookie = {attributes: {}}
          @stack.pop
        else
          cookie[:attributes][normalize_key(pre_match)] = true
        end
      end
    end
    
    yield(cookie)
  end
  
  def normalize_key(key)
    key = key.downcase.gsub('-','_')
    if key == 'port'
      :ports
    elsif key == 'httponly'
      :http_only
    elsif key == 'commenturl'
      :comment_url
    else
      key.to_sym
    end
  end
  
  def normalize_attribute_value(key, value)
    case key
    when :domain
      if value =~ CookieStore::Cookie::IPADDR
        value
      else
        # As per RFC2965 if a host name contains no dots, the effective host
        # name is that name with the string .local appended to it.
        value = "#{value}.local" if !value.include?('.')
        (value.start_with?('.') ? value : ".#{value}").downcase
      end
    when :expires
      byebug if $debug
      case value
      when /\w{3}, \d{2}-\w{3}-\d{2} /
        DateTime.strptime(value, '%a, %d-%b-%y %H:%M:%S %Z')
      when /\w{3}, \d{2}-\w{3}-\d{4} /
        DateTime.strptime(value, '%a, %d-%b-%Y %H:%M:%S %Z')
      when /\w{3}, \d{2} \w{3} \d{2} /
        DateTime.strptime(value, '%a, %d %b %y %H:%M:%S %Z')
      when /\w{3}, \d{2} \w{3} \d{4} /
        DateTime.strptime(value, '%a, %d %b %Y %H:%M:%S %Z')
      else
        nil
        # DateTime.strptime(value, '%a, %d %b %Y %H:%M:%S %Z')
      end
    when :max_age
      value&.to_i
    when :ports
      value.split(',').map(&:to_i)
    when :version
      value.to_i
    else
      value
    end
  end
  
end