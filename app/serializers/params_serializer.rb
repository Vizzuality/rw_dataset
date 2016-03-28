class ParamsSerializer < ActiveModel::Serializer
  attributes :param_type, :key_name, :value
end
