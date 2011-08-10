module RedisAssociations
  RA_PREFIX = 'ra'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def has_many_through_redis(associations, options={})
      redis_association(associations, true, options)
    end

    def has_one_through_redis(association, options={})
      redis_association(association, false, options)
    end


    protected

    # association = :models or :'pkg/models' for many
    # association = :model or :'pkg/model' for one
    def redis_association(association, many, options={})
      # full_association_class_name = 'Model' or 'Pkg::Model'
      full_association_class_name = association.to_s.singularize.camelize
      # association_class_name = 'Model'
      association_class_name = full_association_class_name.demodulize
      # attribute = :model or :models
      attribute = options[:as] || association_class_name
      attribute = (many ? attribute.pluralize : attribute).underscore.to_sym
      # id_attribute = :model_id or :model_ids
      id_attribute = association_class_name.foreign_key
      id_attribute = (many ? id_attribute.pluralize : id_attribute).to_sym
      # association_key_method = :models_key
      association_key_method = "#{attribute.to_s.pluralize}_key".to_sym # always plural, regardless of the value of many

      # def model or models
      define_method(attribute) do
        ids = self.send(id_attribute)
        objects = full_association_class_name.constantize.find(ids)
      end

      # def model_id or model_ids
      define_method(id_attribute) do
        key = self.send(association_key_method)
        ids = redis.smembers(key).map(&:to_i)
        if many
          ids
        else
          ids.first
        end
      end

      # def models=
      define_method(:"#{attribute}=") do |objects|
        # TODO allow id attribute other than "id""
        ids = if many
          objects.map(&:id)
              else
          objects.id
        end
        self.send(:"#{id_attribute}=", ids)
      end

      # def model_ids=
      define_method(:"#{id_attribute}=") do |ids|
        key = self.send(association_key_method)
        redis.del key
        [ids].flatten.each do |oid|
          redis.sadd key, oid
        end
      end

      # def models_key
      define_method(association_key_method) do
        # e.g.: ra:post:1234:comments
        raise "id must be set" unless self.id
        self.class.send(association_key_method, self.id, options)
      end

      elv = self
      self.class.instance_eval do
        # def self.models_key
        define_method(association_key_method) do |_id, *options|
          options ||= {}
          raise "id must be given" unless _id
          if options.delete(:keep_package_name)
            "#{RA_PREFIX}:#{self.to_s.underscore}:#{_id}:#{id_attribute}"
          else
            "#{RA_PREFIX}:#{self.to_s.demodulize.underscore}:#{_id}:#{id_attribute}"
          end
        end
      end
    end
  end

  def redis
    @@redis ||= Redis.new
  end
end
