/* This file is part of the Spring engine (GPL v2 or later), see LICENSE.html */

#ifndef OBJPARSER_HDR
#define OBJPARSER_HDR

#include <map>
#include "IModelParser.h"

struct SOBJTriangle {
	int vIndices[3];   // index of 1st/2nd/3rd vertex
	int nIndices[3];   // index of 1st/2nd/3rd normal
	int tIndices[3];   // index of 1st/2nd/3rd txcoor
};

struct SOBJPiece: public S3DModelPiece {
public:
	SOBJPiece() {
		vertexCount = 0;
		displist    = 0;
		isEmpty     = true;
		type        = MODELTYPE_OBJ;
		colvol      = NULL;
	}
	~SOBJPiece() {
		vertices.clear();
		vnormals.clear();
		texcoors.clear();

		triangles.clear();

		sTangents.clear();
		tTangents.clear();
	}

	void SetVertexTangents();

	void AddVertex(const float3& v) { vertices.push_back(v); vertexCount += 1; }
	void AddNormal(const float3& n) { vnormals.push_back(n);                   }
	void AddTxCoor(const float2& t) { texcoors.push_back(t);                   }

	void AddTriangle(const SOBJTriangle& t) { triangles.push_back(t); }
	const SOBJTriangle& GetTriangle(int idx) const { return triangles[idx]; }
	int GetTriangleCount() const { return (triangles.size()); }

	const float3& GetVertexPos(const int& idx) const { return GetVertex(idx); }
	const float3& GetVertex(const int idx) const { return vertices[idx]; }
	const float3& GetNormal(const int idx) const { return vnormals[idx]; }
	const float3& GetSTangent(const int idx) const { return sTangents[idx]; }
	const float3& GetTTangent(const int idx) const { return tTangents[idx]; }
	const float2& GetTxCoor(const int idx) const { return texcoors[idx]; }

private:
	std::vector<float3> vertices;
	std::vector<float3> vnormals;
	std::vector<float2> texcoors;

	std::vector<SOBJTriangle> triangles;

	std::vector<float3> sTangents;
	std::vector<float3> tTangents;
};

class LuaTable;
class COBJParser: public IModelParser {
public:
	S3DModel* Load(const std::string&);
	void Draw(const S3DModelPiece*) const;

private:
	bool ParseModelData(S3DModel*, const std::string&, const LuaTable&);
	bool BuildModelPieceTree(S3DModel*, const std::map<std::string, SOBJPiece*>&, const LuaTable&);
	void BuildModelPieceTreeRec(S3DModelPiece*, const std::map<std::string, SOBJPiece*>&, const LuaTable&);
};

#endif