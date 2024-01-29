class Draft < ActiveRecord::Base
  belongs_to :draftable, polymorphic: true, optional: true
  belongs_to :user, polymorphic: true 
  belongs_to :parent, polymorphic: true
  has_many :child_drafts, class_name: 'Draft', foreign_key: 'parent_id', dependent: :destroy

  validates_presence_of :data, :draftable_type

  def restore
    draftable.update(data)

    self.child_drafts.each do |child_draft|
      if child_draft.draftable_id.nil?
        child_draft.draftable = child_draft.draftable_type.constantize.new
        child_draft.draftable.save
      else
        child_draft.draftable.update(child_draft.data)
      end
    end
    self.destroy
    self.child_drafts.destroy_all
  end

  def load(object)
    object.assign_attributes(self.data)
    child_associations = object.class.draft_childs || []

    child_associations.each do |association|
      null_drafts = []

      child_drafts.where(draftable_type: association.to_s.camelize.singularize).each do |child_draft|
        if child_draft.draftable_id.nil?
          null_drafts << child_draft
        else
          child_draft.draftable.assign_attributes(child_draft.data)
        end
      end
      # get the existing built records 
      existing_records = object.send(association.to_s.underscore.pluralize)
      if existing_records.blank? and null_drafts.present?
        null_drafts.each do |null_draft|
          object.send(association.to_s.underscore.pluralize).build(null_draft.data)
        end
      end
    end
  end

  def restore_attributes
    draftable.assign_attributes(data)
  end

end
