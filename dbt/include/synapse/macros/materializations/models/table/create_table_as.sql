{% macro synapse__create_table_as(temporary, relation, sql) -%}
    {%- set index = config.get('index', default="CLUSTERED COLUMNSTORE INDEX") -%}
    {%- set dist = config.get('dist', default="ROUND_ROBIN") -%}

    {% set tmp_vw_relation = relation.incorporate(path={"identifier": relation.identifier ~ '_vw'}, type='view')-%}

    {{ get_create_view_as_sql(tmp_vw_relation, sql) }}

    {% set contract_config = config.get('contract') %}

    {% if contract_config.enforced %}

        CREATE TABLE {{relation}}
        {{ build_columns_constraints(relation) }}
        WITH(
            DISTRIBUTION = {{dist}},
            {{index}}
        )

        {{ get_assert_columns_equivalent(sql)  }}

        {% set listColumns %}
            {% for column in model['columns'] %}
                {{ "["~column~"]" }}{{ ", " if not loop.last }}
            {% endfor %}
        {%endset%}

        INSERT INTO {{relation}} ({{listColumns}})
        SELECT {{listColumns}} FROM {{tmp_vw_relation}}

    {%- else %}
        EXEC('CREATE TABLE {{relation}} WITH(DISTRIBUTION = {{dist}},{{index}}) AS SELECT * FROM {{tmp_vw_relation}}');
    {% endif %}
{% endmacro %}
