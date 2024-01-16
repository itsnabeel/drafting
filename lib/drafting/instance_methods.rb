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
      self.draft_id = draft.id if result
      result
    end

    def update_draft(user, attributes)
      with_transaction_returning_status do
        assign_attributes(attributes)
        save_draft(user)
      end
    end

    def clear_user_drafts
      Draft.where(user: user).where(draftable_type: self.class.name, draftable_id: self.id).destroy_all
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
