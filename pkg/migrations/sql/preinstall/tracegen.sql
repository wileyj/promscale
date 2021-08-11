
-- load the attribute_key and attribute tables with resource and span attributes
do $do$
declare
    _attr record;
begin
    for _attr in
    (
        select distinct
          j->>'key' as key
        , jsonb_path_query_first(j, '$.value.*') as value
        , s.attribute_type
        from
        (
            values
            (resource_attribute_type(), '$.resource.attributes[*]'),
            (span_attribute_type(), '$.instrumentationLibrarySpans[*].spans[*].attributes[*]')
        ) s(attribute_type, path)
        cross join
        (
            select jsonb_path_query(t.trace, '$.resourceSpans[*]') as trace
            from trace_stg t
        ) t
        cross join lateral jsonb_path_query(
        t.trace,
        s.path::jsonpath
        ) j
    )
    loop
        perform put_attribute_key(_attr.key, _attr.attribute_type);
        perform put_attribute(_attr.key, _attr.value, _attr.attribute_type);
    end loop;
end;
$do$;

select * from attribute_key;
select * from attribute;