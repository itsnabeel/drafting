module Drafting
  module ClassMethods
    def from_draft(draft_or_id)
      draft = draft_or_id.is_a?(Draft) ? draft_or_id : Draft.find(draft_or_id)
      raise ArgumentError unless draft.draftable_type == name

      target = draft.draftable_type.constantize.new
      target.data = draft.data
      target.send("#{draft_parent}=", draft.parent) if draft_parent
      target
    end

    def drafts(user)
      Draft.where(user: user, draftable_type: name)
    end
  end
end
