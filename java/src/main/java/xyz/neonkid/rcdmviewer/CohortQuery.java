package xyz.neonkid.rcdmviewer;

import org.ohdsi.circe.cohortdefinition.CohortExpressionQueryBuilder;

/**
 * Created by neonkid on 6/23/19
 */

class CohortQuery {
    String generateSql(String op, String exp) {
        GeneratedSqlRequest request = new GeneratedSqlRequest(op, exp);

        CohortExpressionQueryBuilder.BuildExpressionQueryOptions options = request.options;
        CohortExpressionQueryBuilder builder = new CohortExpressionQueryBuilder();

        if(options == null)
            options = new CohortExpressionQueryBuilder.BuildExpressionQueryOptions();

        String sql = builder.buildExpressionQuery(request.expression, options);
        String res = sql.replaceAll("[\\{\\}!?]", "");

        for (int i = 0; i <= 10; i++) {
            String regex = i + " = 0";
            res = res.replaceAll(regex, "");
        }

        int idx = res.indexOf("TRUNCATE TABLE #best_events;");

        return res.substring(0, idx);
    }
}
