require 'mocha'

class Comment
  include RedisAssociations
  @@all = []
  attr_accessor :id

  def initialize(new_id)
    @@all[new_id.to_i] = self
    self.id = new_id
  end

  def self.find(ids)
    ids = [ids].flatten
    ids.map{|i| @@all[i.to_i]}
  end


end

class Article
  include RedisAssociations
  has_many_through_redis :comments

  @@all = []
  attr_accessor :id

  def initialize(new_id)
    @@all[new_id.to_i] = self
    self.id = new_id
  end

  def self.find(ids)
    ids = [ids].flatten
    ids.map{|i| @@all[i.to_i]}
  end

end


class User
  include RedisAssociations
  has_many_through_redis :articles
  has_many_through_redis :comments

  @@all = []
  attr_accessor :id

  def initialize(new_id)
    @@all[new_id.to_i] = self
    self.id = new_id
  end

  def self.find(ids)
    ids = [ids].flatten
    ids.map{|i| @@all[i.to_i]}
  end

end

class RedisAssociationsTest < ActiveSupport::TestCase

  def setup
    Comment.has_one_through_redis :article
    Article.has_one_through_redis :user

#    @sue = User.new.tap{|u| u.id = "Sue"}
  end

  def test_one_to_one
    john = User.new(1)
    mary = User.new(2)

    art1 = Article.new(1)
    art2 = Article.new(2)
    art1.user = john
    art2.user = mary

    assert_equal john, art1.user # TODO allow :as => :author
    assert_equal mary, art2.user
    # TODO opposite direction association
  end


  def test_one_to_many
    art1 = Article.new(1)
    art2 = Article.new(2)
    comment1 = Comment.new(1)
    comment2 = Comment.new(2)
    comment3 = Comment.new(3)

    art1.comments = [comment1, comment2]
    art2.comments = [comment3]

    assert art1.comment_ids.size == 2
    assert art1.comment_ids.include? 1
    assert art1.comment_ids.include? 2

    assert art2.comment_ids.size == 1
    assert art2.comment_ids.include? 3

    assert art1.comments.size == 2
    assert art1.comments.include? comment1
    assert art1.comments.include? comment2

    assert art2.comments.size == 1
    assert art2.comments.include? comment3
  end
end
