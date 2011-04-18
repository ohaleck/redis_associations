module RedisAssociations
  RA_PREFIX = 'ra'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_one_through_redis(association, options={})
      association_class_name = association.to_s.singularize.camelize
      association_name = (options[:as] || association).to_sym
      association_id = "#{association_name.to_s.singularize}_ids".to_sym
      association_key = :"#{association_name}_key"

      define_method(association_name) do
        id = self.send(association_id)
        a = association_class_name.constantize.find(id)
        a.is_a?(Array) ? a.first : a
      end

      define_method(association_id) do
        key = self.send(association_key)
        redis.get(key).to_i
      end

      define_method(:"#{association_name}=") do |object|
        # TODO allow id attribute other than "id""
        # TODO check object class and existence
        self.send(:"#{association_id}=", object.id)
      end

      define_method(:"#{association_id}=") do |_id|
        key = self.send(association_key)
        redis.set key, _id
      end

      define_method(association_key) do
        # e.g.: ra:post:1234:category
        self.class.send(association_key, self.id)
      end

      selv = self
      self.class.instance_eval do
        define_method(association_key) do |_id|
          raise "id must be given" unless _id
          "#{RA_PREFIX}:#{selv.to_s.downcase}:#{_id}:#{association_id}"
        end
      end
    end

    def has_many_through_redis(associations, options={})
      associations_class_name = associations.to_s.singularize.camelize
      associations_name = (options[:as] || associations).to_sym
      association_ids = "#{associations_name.to_s.singularize}_ids".to_sym
      associations_key = :"#{associations_name}_key"

      define_method(associations_name) do
        ids = self.send(association_ids)
        associations_class_name.constantize.find(ids)
      end

      define_method(association_ids) do
        key = self.send(associations_key)
        redis.smembers(key).map(&:to_i)
      end

      define_method(:"#{associations_name}=") do |objects|
        # TODO allow id attribute other than "id""
        ids = objects.map(&:id)
        self.send(:"#{association_ids}=", ids)
      end

      define_method(:"#{association_ids}=") do |ids|
        key = self.send(associations_key)
        redis.sdiffstore key, key, key
        ids.each do |oid|
          redis.sadd key, oid
        end
      end

      define_method(associations_key) do
        # e.g.: ra:post:1234:comments
        self.class.send(associations_key, self.id)
      end

      selv = self
      self.class.instance_eval do
        define_method(associations_key) do |_id|
          raise "id must be given" unless _id
          "#{RA_PREFIX}:#{selv.to_s.downcase}:#{_id}:#{association_ids}"
        end
      end
    end

    protected
  end

  def redis
    @@redis ||= Redis.new
  end

end
