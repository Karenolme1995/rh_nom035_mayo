from typing import Optional

from app.services.nom035_service import require_admin


class Nom035ProfileService:
    def _cursor(self, conn):
        return conn.cursor(dictionary=True)

    def _normalize_rows(self, rows, key_name="label"):
        out = []
        for r in rows or []:
            label = r.get(key_name)
            total = int(r.get("total") or 0)
            out.append({
                "label": str(label).strip() if label is not None and str(label).strip() else "Sin dato",
                "total": total,
            })
        return out

    def _fetch_group_count(
        self,
        cur,
        cycle_id: int,
        field: str,
        submitted_only: bool = True,
        order_by_field: bool = False,
    ):
        status_filter = "AND s.status = 'submitted'" if submitted_only else ""

        order_sql = f"""
            ORDER BY
                CASE
                    WHEN {field} IS NULL OR TRIM({field}) = '' THEN 1
                    ELSE 0
                END,
                {field} ASC
        """ if order_by_field else """
            ORDER BY total DESC, label ASC
        """

        cur.execute(
            f"""
            SELECT
                COALESCE(NULLIF(TRIM(sp.{field}), ''), 'Sin dato') AS label,
                COUNT(*) AS total
            FROM nom035_submission_profile sp
            INNER JOIN nom035_submissions s
                ON s.id = sp.submission_id
            WHERE s.cycle_id = %s
              {status_filter}
            GROUP BY COALESCE(NULLIF(TRIM(sp.{field}), ''), 'Sin dato')
            {order_sql}
            """,
            (int(cycle_id),),
        )
        return self._normalize_rows(cur.fetchall())

    def _fetch_department_results(self, cur, cycle_id: int):
        cur.execute(
            """
            SELECT
                COALESCE(NULLIF(TRIM(a.name), ''), 'Sin área') AS department,
                COUNT(*) AS total,
                ROUND(AVG(COALESCE(s.score_total, 0)), 2) AS avg_score
            FROM nom035_submission_profile sp
            INNER JOIN nom035_submissions s
                ON s.id = sp.submission_id
            LEFT JOIN areas a
                ON a.id = sp.area_id
            WHERE s.cycle_id = %s
              AND s.status = 'submitted'
            GROUP BY COALESCE(NULLIF(TRIM(a.name), ''), 'Sin área')
            ORDER BY total DESC, department ASC
            """,
            (int(cycle_id),),
        )
        rows = cur.fetchall() or []
        return [
            {
                "department": str(r.get("department") or "Sin área"),
                "total": int(r.get("total") or 0),
                "avg_score": float(r.get("avg_score") or 0),
            }
            for r in rows
        ]

    def _fetch_general_summary(self, cur, cycle_id: int):
        cur.execute(
            """
            SELECT
                COUNT(*) AS total_submissions,
                ROUND(AVG(COALESCE(s.score_total, 0)), 2) AS avg_score,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'muy alto' THEN 1 ELSE 0 END) AS muy_alto,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'alto' THEN 1 ELSE 0 END) AS alto,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'medio' THEN 1 ELSE 0 END) AS medio,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'bajo' THEN 1 ELSE 0 END) AS bajo,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) IN ('nulo', '') OR s.risk_level IS NULL THEN 1 ELSE 0 END) AS nulo
            FROM nom035_submission_profile sp
            INNER JOIN nom035_submissions s
                ON s.id = sp.submission_id
            WHERE s.cycle_id = %s
              AND s.status = 'submitted'
            """,
            (int(cycle_id),),
        )
        r = cur.fetchone() or {}
        return {
            "total_submissions": int(r.get("total_submissions") or 0),
            "avg_score": float(r.get("avg_score") or 0),
            "risk_distribution": {
                "Muy alto": int(r.get("muy_alto") or 0),
                "Alto": int(r.get("alto") or 0),
                "Medio": int(r.get("medio") or 0),
                "Bajo": int(r.get("bajo") or 0),
                "Nulo": int(r.get("nulo") or 0),
            },
        }

    def _fetch_category_scores(self, cur, cycle_id: int):
        cur.execute(
            """
            SELECT
                COALESCE(NULLIF(TRIM(category), ''), 'Sin categoría') AS label,
                ROUND(AVG(COALESCE(score, 0)), 2) AS avg_score,
                COUNT(*) AS total
            FROM nom035_submission_category_scores c
            INNER JOIN nom035_submissions s
                ON s.id = c.submission_id
            WHERE s.cycle_id = %s
              AND s.status = 'submitted'
            GROUP BY COALESCE(NULLIF(TRIM(category), ''), 'Sin categoría')
            ORDER BY avg_score DESC, label ASC
            """,
            (int(cycle_id),),
        )
        rows = cur.fetchall() or []
        return [
            {
                "label": str(r.get("label") or "Sin categoría"),
                "avg_score": float(r.get("avg_score") or 0),
                "total": int(r.get("total") or 0),
            }
            for r in rows
        ]

    def _fetch_domain_scores(self, cur, cycle_id: int):
        cur.execute(
            """
            SELECT
                COALESCE(NULLIF(TRIM(domain), ''), 'Sin dominio') AS label,
                ROUND(AVG(COALESCE(score, 0)), 2) AS avg_score,
                COUNT(*) AS total
            FROM nom035_submission_domain_scores d
            INNER JOIN nom035_submissions s
                ON s.id = d.submission_id
            WHERE s.cycle_id = %s
              AND s.status = 'submitted'
            GROUP BY COALESCE(NULLIF(TRIM(domain), ''), 'Sin dominio')
            ORDER BY avg_score DESC, label ASC
            """,
            (int(cycle_id),),
        )
        rows = cur.fetchall() or []
        return [
            {
                "label": str(r.get("label") or "Sin dominio"),
                "avg_score": float(r.get("avg_score") or 0),
                "total": int(r.get("total") or 0),
            }
            for r in rows
        ]

    def _fetch_department_heatmap(self, cur, cycle_id: int):
        cur.execute(
            """
            SELECT
                COALESCE(NULLIF(TRIM(a.name), ''), 'Sin área') AS department,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'muy alto' THEN 1 ELSE 0 END) AS muy_alto,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'alto' THEN 1 ELSE 0 END) AS alto,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'medio' THEN 1 ELSE 0 END) AS medio,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) = 'bajo' THEN 1 ELSE 0 END) AS bajo,
                SUM(CASE WHEN LOWER(COALESCE(s.risk_level, '')) IN ('nulo', '') OR s.risk_level IS NULL THEN 1 ELSE 0 END) AS nulo
            FROM nom035_submission_profile sp
            INNER JOIN nom035_submissions s
                ON s.id = sp.submission_id
            LEFT JOIN areas a
                ON a.id = sp.area_id
            WHERE s.cycle_id = %s
              AND s.status = 'submitted'
            GROUP BY COALESCE(NULLIF(TRIM(a.name), ''), 'Sin área')
            ORDER BY department ASC
            """,
            (int(cycle_id),),
        )
        rows = cur.fetchall() or []
        return [
            {
                "department": str(r.get("department") or "Sin área"),
                "Muy alto": int(r.get("muy_alto") or 0),
                "Alto": int(r.get("alto") or 0),
                "Medio": int(r.get("medio") or 0),
                "Bajo": int(r.get("bajo") or 0),
                "Nulo": int(r.get("nulo") or 0),
            }
            for r in rows
        ]

    def get_profile_stats(self, conn, user: dict, cycle_id: int):
        require_admin(user)
        cur = self._cursor(conn)

        try:
            data = {
                "cycle_id": int(cycle_id),

                # Demográficos / laborales
                "sex": self._fetch_group_count(cur, cycle_id, "sex", submitted_only=True, order_by_field=True),
                "age_range": self._fetch_group_count(cur, cycle_id, "age_range", submitted_only=True, order_by_field=True),
                "education_level": self._fetch_group_count(cur, cycle_id, "education_level", submitted_only=True, order_by_field=False),
                "job_type": self._fetch_group_count(cur, cycle_id, "job_type", submitted_only=True, order_by_field=False),
                "marital_status": self._fetch_group_count(cur, cycle_id, "marital_status", submitted_only=True, order_by_field=False),
                "hiring_type": self._fetch_group_count(cur, cycle_id, "hiring_type", submitted_only=True, order_by_field=False),
                "staff_type": self._fetch_group_count(cur, cycle_id, "staff_type", submitted_only=True, order_by_field=False),
                "workday_type": self._fetch_group_count(cur, cycle_id, "workday_type", submitted_only=True, order_by_field=False),
                "shift_rotation": self._fetch_group_count(cur, cycle_id, "shift_rotation", submitted_only=True, order_by_field=False),
                "total_work_experience": self._fetch_group_count(cur, cycle_id, "total_work_experience", submitted_only=True, order_by_field=True),
                "time_current_position": self._fetch_group_count(cur, cycle_id, "time_current_position", submitted_only=True, order_by_field=True),

                # Resultados consolidados
                "final_study_data": self._fetch_general_summary(cur, cycle_id),
                "general_synthesized_report": self._fetch_general_summary(cur, cycle_id),
                "domain_scores": self._fetch_domain_scores(cur, cycle_id),
                "category_scores": self._fetch_category_scores(cur, cycle_id),
                "risk_distribution": self._fetch_general_summary(cur, cycle_id)["risk_distribution"],
                "department_results": self._fetch_department_results(cur, cycle_id),
                "department_heatmap": self._fetch_department_heatmap(cur, cycle_id),
            }
            return data

        finally:
            cur.close()


nom035_profile_service = Nom035ProfileService()