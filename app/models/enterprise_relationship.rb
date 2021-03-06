class EnterpriseRelationship < ActiveRecord::Base
  belongs_to :parent, class_name: 'Enterprise', touch: true
  belongs_to :child, class_name: 'Enterprise', touch: true
  has_many :permissions, class_name: 'EnterpriseRelationshipPermission', dependent: :destroy

  validates_presence_of :parent_id, :child_id
  validates_uniqueness_of :child_id, scope: :parent_id, message: "^That relationship is already established."

  scope :with_enterprises,
    joins('LEFT JOIN enterprises AS parent_enterprises ON parent_enterprises.id = enterprise_relationships.parent_id').
    joins('LEFT JOIN enterprises AS child_enterprises ON child_enterprises.id = enterprise_relationships.child_id')

  scope :involving_enterprises, ->(enterprises) {
    where('parent_id IN (?) OR child_id IN (?)', enterprises, enterprises)
  }

  scope :permitting, ->(enterprises) { where('child_id IN (?)', enterprises) }
  scope :permitted_by, ->(enterprises) { where('parent_id IN (?)', enterprises) }

  scope :with_permission, ->(permission) {
    joins(:permissions).
    where('enterprise_relationship_permissions.name = ?', permission)
  }

  scope :by_name, with_enterprises.order('child_enterprises.name, parent_enterprises.name')


  # Load an array of the relatives of each enterprise (ie. any enterprise related to it in
  # either direction). This array is split into distributors and producers, and has the format:
  # {enterprise_id => {distributors: [id, ...], producers: [id, ...]} }
  def self.relatives(activated_only=false)
    relationships = EnterpriseRelationship.includes(:child, :parent)
    relatives = {}

    relationships.each do |r|
      relatives[r.parent_id] ||= {distributors: Set.new, producers: Set.new}
      relatives[r.child_id]  ||= {distributors: Set.new, producers: Set.new}

      if !activated_only || r.child.activated?
        relatives[r.parent_id][:producers]    << r.child_id if r.child.is_primary_producer
        relatives[r.parent_id][:distributors] << r.child_id if r.child.is_distributor
      end

      if !activated_only || r.parent.activated?
        relatives[r.child_id][:producers]    << r.parent_id if r.parent.is_primary_producer
        relatives[r.child_id][:distributors] << r.parent_id if r.parent.is_distributor
      end
    end

    relatives
  end


  def permissions_list=(perms)
    perms.andand.each { |name| permissions.build name: name }
  end

  def has_permission?(name)
    permissions.map(&:name).map(&:to_sym).include? name.to_sym
  end
end
