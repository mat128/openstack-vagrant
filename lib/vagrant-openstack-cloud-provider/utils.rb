class InvalidValue < StandardError
end

def greater_than(base_value)
  lambda { |val| val > base_value }
end


def casting_attr_accessor(accessor, type, *validators)

  define_method(accessor) do
    instance_variable_get("@#{accessor}")
  end

  define_method("#{accessor}=") do |val|
    new_val = Kernel.send(type.to_s, val)
    if validators and ! validators.all? {|v| v.call(new_val) }
      raise InvalidValue, val
    end

    instance_variable_set("@#{accessor}", new_val)
  end
end

