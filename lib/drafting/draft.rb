class Draft < ActiveRecord::Base
  belongs_to :draftable, polymorphic: true
  belongs_to :user, polymorphic: true
  belongs_to :parent, polymorphic: true

  validates_presence_of :data, :draftable_type

  def restore
    draftable.update(data)
    self.destroy
  end

  def restore_attributes
    draftable.assign_attributes(data)
  end

end
