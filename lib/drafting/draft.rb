class Draft < ActiveRecord::Base
  belongs_to :draftable, polymorphic: true, optional: true
  belongs_to :user, polymorphic: true 
  belongs_to :parent, polymorphic: true
  has_many :child_drafts, class_name: 'Draft', foreign_key: 'parent_id', dependent: :destroy

  validates_presence_of :data, :draftable_type

  def restore
    draftable.update(data)
    self.child_drafts(self).each do |child_draft|
      child_draft.draftable.update(child_draft.data)
    end
    self.destroy
    self.child_drafts.destroy_all
  end

  def restore_attributes
    draftable.assign_attributes(data)
  end

end
