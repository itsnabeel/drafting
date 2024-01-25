module Drafting
  module InstanceMethods
    def save_draft(user=nil)
      draft = Draft.where(user: user).where(draftable_type: self.class.name, draftable_id: self.id).first || Draft.new

      draft.data = self.attributes 
      draft.draftable_type = self.class.name
      draft.draftable_id = self.id
      draft.user_id = user.try(:id)
      draft.user_type = user.try(:class).try(:name)
      draft.parent = self.send(self.class.draft_parent) if self.class.draft_parent
      result = draft.save
      self.create_child_drafts(draft) if result
      self.draft_id = draft.id if result
      result
    end

    def create_child_drafts(parent_draft)
      if self.class.draft_childs.present?
        self.class.draft_childs.each do |child|
          association = self.class.reflect_on_all_associations.find { |a| a.name == child }
          if association.present? && association.macro == :has_many
            self.send(child).each do |associated_object| 
              if associated_object.id == nil
                draft = Draft.new(user_id: parent_draft.user_id , draftable_type: associated_object.class.name, parent_id: parent_draft.id)
              else
                draft = Draft.where(user_id: parent_draft.user_id , draftable_type: associated_object.class.name, parent_id: parent_draft.id).first_or_initialize
              end
              draft.data = associated_object.attributes
              draft.draftable_type = associated_object.class.name
              draft.draftable_id = associated_object.id
              draft.user_id = parent_draft.user.id
              draft.user_type = parent_draft.user.class.name
              draft.parent = parent_draft
              draft.save
            end
          end
        end
      end
    end

    def child_drafts(parent_draft)
      Draft.where(parent_id: parent_draft.id)
    end

    def update_draft(user, attributes)
      with_transaction_returning_status do
        assign_attributes(attributes)
        save_draft(user)
      end
    end

    def clear_user_drafts(user)
      Draft.where(user_id: user.id).where(draftable_type: self.class.name, draftable_id: self.id).destroy_all
    end

    def clear_drafts
      Draft.where(draftable_type: self.class.name, draftable_id: self.id).destroy_all
    end

    def drafted_by(user)
      Draft.where(user_id: user.id).where(draftable: self).first
    end

  private

    def clear_draft
      if draft = Draft.find_by_id(self.draft_id)
        self.draft_id = nil if draft.destroy
      end
    end
  end
end