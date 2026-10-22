class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :key, null: false, index: {unique: true}
      t.string :value

      t.timestamps
    end
  end
end
