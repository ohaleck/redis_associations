module RedisAssociations
  RA_PREFIX = 'ra'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def has_one_through_redis(association, options={})
      # association = :model or :pkg/model'
      # full_association_class_name = 'Model' or 'Pkg::Model'
      full_association_class_name = association.to_s.singularize.camelize
      # association_class_name = 'Model'
      association_class_name = full_association_class_name.demodulize
      # association_name = :model
      association_name = (options[:as] || association_class_name.underscore).to_sym
      # association_id = :model_id
      association_id = association_class_name.foreign_key.to_sym
      # association_key = :models_key
      association_key = "#{association_name.to_s.pluralize}_key".to_sym

      #  def models
      define_method(association_name) do
        id = self.send(association_id)
        a = association_class_name.constantize.find(id)
        a.is_a?(Array) ? a.first : a
      end

      # def model_ids
      define_method(association_id) do
        key = self.send(association_key)
        redis.get(key).to_i
      end

      # def models=
      define_method(:"#{association_name}=") do |object|
        # TODO allow id attribute other than "id""
        # TODO check object class and existence
        self.send(:"#{association_id}=", object.id)
      end

      # def model_ids=
      define_method(:"#{association_id}=") do |_id|
        key = self.send(association_key)
        redis.set key, _id
      end

      # def models_key
      define_method(association_key) do
        # e.g.: ra:post:1234:category
        self.class.send(association_key, self.id)
      end

      selv = self
      self.class.instance_eval do
        # def self.models_key
        define_method(association_key) do |_id|
          raise "id must be given" unless _id
          "#{RA_PREFIX}:#{selv.to_s.downcase}:#{_id}:#{association_id}"
        end
      end
    end

    def has_many_through_redis(associations, options={})
      # associations = :models or :'pkg/models'
      # full_association_class_name = 'Model' or 'Pkg::Model'
      full_associations_class_name = associations.to_s.singularize.camelize
      # association_class_name = 'Model'
      associations_class_name = full_associations_class_name.demodulize
      # association_name = :models
      associations_name = (options[:as] || associations_class_name.pluralize.underscore).to_sym
      # association_ids = :model_ids
      association_ids = associations_class_name.foreign_key.pluralize.to_sym
      # associations_key = :models_key
      associations_key = "#{associations_name}_key".to_sym
      
      # def models
      define_method(associations_name) do
        ids = self.send(association_ids)
        full_associations_class_name.constantize.find(ids)
      end

      # def model_ids
      define_method(association_ids) do
        key = self.send(associations_key)
        redis.smembers(key).map(&:to_i)
      end

      # def models=
      define_method(:"#{associations_name}=") do |objects|
        # TODO allow id attribute other than "id""
        ids = objects.map(&:id)
        self.send(:"#{association_ids}=", ids)
      end

      # def model_ids=
      define_method(:"#{association_ids}=") do |ids|
        key = self.send(associations_key)
        redis.sdiffstore key, key, key
        ids.each do |oid|
          redis.sadd key, oid
        end
      end

      # def models_key
      define_method(associations_key) do
        # e.g.: ra:post:1234:comments
        self.class.send(associations_key, self.id)
      end

      selv = self
      self.class.instance_eval do
        # def self.models_key
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
