class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name.to_s) do
        instance_variable_get("@#{name}")
      end
      define_method("#{name.to_s}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end
end
