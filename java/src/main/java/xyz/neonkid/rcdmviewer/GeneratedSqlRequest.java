package xyz.neonkid.rcdmviewer;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.*;
import com.google.gson.Gson;
import com.google.gson.stream.JsonReader;
import org.ohdsi.circe.cohortdefinition.CohortExpression;
import org.ohdsi.circe.cohortdefinition.CohortExpressionQueryBuilder;

import java.io.StringReader;

/**
 * Created by neonkid on 6/23/19
 */

class GeneratedSqlRequest {
    CohortExpression expression;
    CohortExpressionQueryBuilder.BuildExpressionQueryOptions options;

    private <T> T deserialize(String data, TypeReference<T> typeRef) {
        ObjectMapper objectMapper = new ObjectMapper();
        if (data == null)
            return null;
        else {
            try {
                return objectMapper.readValue(data, typeRef);
            } catch (Exception ex) {
                throw new RuntimeException(ex);
            }
        }
    }

    GeneratedSqlRequest(String op, String exp) {
        this.expression = deserialize(exp, new TypeReference<CohortExpression>() {});

        Gson gson = new Gson();
        JsonReader or = new JsonReader(new StringReader(op));
        this.options = gson.fromJson(or, CohortExpressionQueryBuilder.BuildExpressionQueryOptions.class);
    }
}
